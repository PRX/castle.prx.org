#!/usr/bin/env ruby
require 'optparse'
require 'google/cloud/bigquery'
require 'google/cloud/storage'

options = {local: false}
parser = OptionParser.new do |opt|
  opt.banner = %q(Usage: load_data.rb [options]

    Load a schema-converted day of data into new dt_downloads table
  )
  opt.on('-t', '--time TIME', 'Day to run this for YYYY-MM-DD') { |o| options[:time] = o }
  opt.on('-p', '--project PROJECT', 'BigQuery project name') { |o| options[:project] = o }
  opt.on('-d', '--dataset DATASET', 'BigQuery dataset name') { |o| options[:dataset] = o }
  opt.on('-b', '--bucket BUCKET', 'Storage bucket name') { |o| options[:bucket] = o }
  opt.on('-l', '--local', 'Use local google creds') { |o| options[:local] = true }
end
parser.parse!

abort "Missing required param: time\n\n#{parser}" if options[:time].nil? || options[:time].empty?
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

bigquery = Google::Cloud::Bigquery.new(project: options[:project], keyfile: KEYFILE)
dataset = bigquery.dataset(options[:dataset])
abort "Dataset '#{options[:dataset]}' does not exist!" unless dataset

storage = Google::Cloud::Storage.new(project: options[:project], keyfile: KEYFILE)
bucket = storage.bucket(options[:bucket])
abort "Bucket '#{options[:bucket]}' does not exist!" unless bucket

# (1) find the file to load
puts "Loading data for #{options[:time]}"
print '  looking for backup file -> '
file = bucket.files(prefix: "migrate_downloads/#{options[:dataset]}_out/downloads_#{options[:time].gsub('-', '')}").first
abort 'does not exist!' unless file
puts "#{File.basename(file.name)}"

# (2) check that bigquery doesn't already have this day
print '  making sure bigquery dt_downloads is empty -> '
sql = "SELECT COUNT(*) AS count FROM dt_downloads WHERE EXTRACT(DATE FROM timestamp) = '#{options[:time]}'"
count = dataset.query(sql, cache: false).first[:count]
puts "#{count} rows"
abort '  cannot load a non-empty day!' unless count == 0

# (3) load the data
print '  running load job -> '
job = dataset.table('dt_downloads').load_job "gs://#{options[:bucket]}/#{file.name}",
  format: 'csv', create: 'never', write: 'append', skip_leading: 1
job.wait_until_done!
if job.failed?
  puts 'FAILED!'
  job.errors.each { |e| puts "    #{e}" }
  exit 1
else
  puts "loaded #{job.output_rows} rows"
end

# (4) sanity check
print '  querying tables -> '
old_sql = "SELECT COUNT(*) AS count FROM downloads WHERE _PARTITIONTIME = '#{options[:time]}'"
old_count = dataset.query(old_sql, cache: false).first[:count]
new_count = dataset.query(sql, cache: false).first[:count]
puts "#{old_count} downloads / #{new_count} dt_downloads"
if old_count == new_count
  puts '  complete!'
else
  abort "  well that's not right"
end
