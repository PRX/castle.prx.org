#!/usr/bin/env ruby
require 'optparse'
require 'pg'
require 'google/cloud/bigquery'
require 'pry'

options = {local: false}
parser = OptionParser.new do |opt|
  opt.banner = %q(Usage: load_categories.rb [options]

    Load feeder episode-categories into bigquery
  )
  opt.on('-e', '--environment ENV', 'aws-secrets env name') { |o| options[:environment] = o }
  opt.on('-p', '--project PROJECT', 'BigQuery project name') { |o| options[:project] = o }
  opt.on('-d', '--dataset DATASET', 'BigQuery dataset name') { |o| options[:dataset] = o }
  opt.on('-l', '--local', 'Use local google creds') { |o| options[:local] = true }
end
parser.parse!

abort "Missing required param: environment\n\n#{parser}" if options[:environment].nil? || options[:environment].empty?
abort "Missing required param: project\n\n#{parser}" if options[:project].nil? || options[:project].empty?
abort "Missing required param: dataset\n\n#{parser}" if options[:dataset].nil? || options[:dataset].empty?

HERE = File.expand_path(File.dirname(__FILE__))
KEYFILE = if options[:local] then
  nil
elsif File.exists?("#{HERE}/.credentials.json")
  "#{HERE}/.credentials.json"
else
  abort "You must add a .credentials.json file in the scripts directory!\n\n#{parser}"
end

bigquery = Google::Cloud::Bigquery.new(project: options[:project], keyfile: "#{HERE}/.credentials.json")
dataset = bigquery.dataset(options[:dataset])
abort "Dataset '#{options[:dataset]}' does not exist!" unless dataset

puts "loading data from feeder #{options[:environment]}..."
print '  loading aws-secrets '
command = "aws-secrets-get feeder current #{options[:environment]}"
output = `#{command} | grep DB_`
abort "ERROR running aws-secrets-get!" unless $? == 0
envs = output.split("\n").reject(&:empty?).map{ |l| [l.split('=')[0], l.split('=')[1]] }.to_h
db_addr = envs['DB_PORT_5432_TCP_ADDR']
db_port = envs['DB_PORT_5432_TCP_PORT']
db_name = envs['DB_ENV_POSTGRES_DATABASE']
db_user = envs['DB_ENV_POSTGRES_USER']
db_pass = envs['DB_ENV_POSTGRES_PASSWORD']
puts '-> ok'

print "  checking connection to #{envs['DB_PORT_5432_TCP_ADDR']} "
conn = PG.connect(db_addr, db_port, '', '', db_name, db_user, db_pass)
where = "where categories is not null and categories != '[]'"
res  = conn.exec("select count(*) from episodes #{where}")
abort "BAD result: #{res.first.to_s}" unless res.first['count'].to_i > 0
puts '-> ok'

print "  downloading categories for #{res.first['count']} episodes "
res = conn.exec("select guid, categories from episodes #{where}")
puts '-> ok'

print '  writing categories.json '
Dir.mkdir("#{HERE}/tmp") unless Dir.exists?("#{HERE}/tmp")
File.open("#{HERE}/tmp/categories.json", 'w') do |file|
  res.each do |row|
    cats = JSON.parse(row['categories'])

    # normalize using the same logic as dovetail
    # https://github.com/PRX/dovetail.prx.org/blob/master/models/decision.js#L79
    normalized = cats.map do |c|
      c.downcase.gsub(/[:,]/, ' ').gsub(/[^ a-zA-Z0-9_-]/, '').gsub(/\s+/, ' ').strip
    end

    normalized.uniq.each do |cat|
      file << JSON.generate({feeder_episode: row['guid'], category: cat}) + "\n"
    end
  end
end
print '-> gzipping '
`gzip -f #{HERE}/tmp/categories.json`
puts '-> done'

puts "checking #{options[:dataset]}.categories table..."
print '  dropping '
table = dataset.table('categories')
if table
  puts '-> dropped'
  table.delete
else
  puts '-> already gone'
end
print '  creating '
table = dataset.create_table 'categories' do |schema|
  schema.string 'feeder_episode', mode: :required
  schema.string 'category'
end
puts '-> ok'

puts "inserting into #{options[:dataset]}.categories..."
print '  uploading categories.json job '
json = File.open("#{HERE}/tmp/categories.json.gz")
job = table.load_job(json, format: 'json', create: 'never', write: 'empty')
puts '-> done'
print '  running job '
job.wait_until_done!
if job.failed?
  puts '-> FAILED!'
  job.errors.each { |e| puts "    #{e}" }
else
  puts "-> loaded #{job.output_rows} rows"
end
