#!/usr/bin/env ruby
require 'optparse'
require 'csv'
require 'google/cloud/bigquery'
require 'google/cloud/storage'

options = {numdays: 1, local: false}
parser = OptionParser.new do |opt|
  opt.banner = %q(Usage: export_to_csv.rb [options]

    Backup bigquery partition days to google cloud storage
  )
  opt.on('-p', '--project PROJECT', 'BigQuery project name') { |o| options[:project] = o }
  opt.on('-d', '--dataset DATASET', 'BigQuery dataset name') { |o| options[:dataset] = o }
  opt.on('-b', '--bucket BUCKET', 'Storage bucket name') { |o| options[:bucket] = o }
  opt.on('-n', '--numdays days', OptionParser::OctalInteger, 'Number of days of data to copy') { |o| options[:numdays] = o }
  opt.on('-l', '--local', 'Use local google creds') { |o| options[:local] = true }
end
parser.parse!

abort "Missing required param: project\n\n#{parser}" if options[:project].nil? || options[:project].empty?
abort "Missing required param: dataset\n\n#{parser}" if options[:dataset].nil? || options[:dataset].empty?
abort "Missing required param: bucket\n\n#{parser}" if options[:bucket].nil? || options[:bucket].empty?

HERE = File.expand_path(File.dirname(__FILE__))
KEYFILE = if options[:local] then
  nil
elsif File.exists?("#{HERE}/.credentials.json")
  "#{HERE}/.credentials.json"
else
  abort "You must add a .credentials.json file in the scripts directory!\n\n#{parser}"
end
GS_BUCKET = "gs://#{options[:bucket]}"
GS_PATH = "migrate_downloads/#{options[:dataset]}"

bigquery = Google::Cloud::Bigquery.new(project: options[:project], keyfile: KEYFILE)
dataset = bigquery.dataset(options[:dataset])
abort "Dataset '#{options[:dataset]}' does not exist!" unless dataset

storage = Google::Cloud::Storage.new(project: options[:project], keyfile: KEYFILE)
bucket = storage.bucket(options[:bucket])
abort "Bucket '#{options[:bucket]}' does not exist!" unless bucket

# (1) generate date range
puts 'Generating dates to export'
print '  querying bigquery -> '
result = dataset.query('SELECT EXTRACT(DATE FROM _PARTITIONTIME) as pt FROM downloads GROUP BY pt ORDER BY pt desc')
puts "#{result.count} partitions"
print "  scanning gs://#{options[:bucket]} -> "
page = bucket.files(prefix: "#{GS_PATH}/")
files = [].concat(page)
while page.token
  page = bucket.files(prefix: "#{GS_PATH}/", token: page.token)
  files.concat(page)
end
puts "#{files.count} files"
print '  finding missing days -> '
done = files.map {|file| file.name.gsub("#{GS_PATH}/", '').split('/').first }.uniq
todo = result.map {|row| row[:pt].to_s} - done - [Date.today.to_s]
puts "#{done.count} done, #{todo.count} todo"
todo = todo[0..(options[:numdays] - 1)]
puts "  processing #{todo.count} now"

# (2) export to tmp table
puts 'Exporting partitions'
puts '  querying into tmp tables:'
jobs = []
todo.each do |date|
  tmp_name = "downloads_tmp_migrate_#{date.gsub('-', '')}"
  tmp_table = dataset.table(tmp_name) || dataset.create_table(tmp_name)
  puts "    downloads -> #{tmp_name}"
  sql = "SELECT * FROM downloads WHERE _PARTITIONTIME = '#{date}'"
  jobs << dataset.query_job(sql, table: tmp_table, large_results: true, create: 'needed', write: 'truncate')
end

# (3) wait for exports to finish
puts '  waiting for queries to finish:'
jobs.each_with_index do |job, idx|
  job.wait_until_done!
  if job.failed?
    puts "  FAILED on #{todo[idx]}"
    job.errors.each { |e| puts "    #{e}" }
  else
    puts "    #{todo[idx]} done #{job.bytes_processed / 1000 / 1000} mb"
  end
end

# (4) extract to csv files
puts "Dumping CSV files to storage"
puts "  extracting to bucket #{GS_BUCKET}:"
jobs = []
todo.each do |date|
  tmp_name = "downloads_tmp_migrate_#{date.gsub('-', '')}"
  tmp_table = dataset.table(tmp_name)
  puts "    #{tmp_name} -> #{GS_PATH}/#{date}/downloads_*.csv"
  jobs << tmp_table.extract_job("#{GS_BUCKET}/#{GS_PATH}/#{date}/downloads_*.csv")
end

# (5) wait for extracts to finish
puts '  waiting for extract jobs to finish:'
jobs.each_with_index do |job, idx|
  job.wait_until_done!
  if job.failed?
    puts "  FAILED on #{todo[idx]}"
    job.errors.each { |e| puts "    #{e}" }
  else
    puts "    #{todo[idx]} #{job.destinations_file_counts.map(&:to_i).inject(:+)} files"
  end
end

# (6) cleanup
puts 'Dropping tmp tables'
todo.each do |date|
  tmp_name = "downloads_tmp_migrate_#{date.gsub('-', '')}"
  tmp_table = dataset.table(tmp_name)
  print "  #{tmp_name} -> "
  tmp_table.delete
  puts 'dropped!'
end
