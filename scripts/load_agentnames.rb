#!/usr/bin/env ruby
require 'optparse'
require 'google/cloud/bigquery'
require 'yaml'

options = {}
parser = OptionParser.new do |opt|
  opt.banner = %q(Usage: load_agentnames.rb [options]

    Load the agentnames table from the prx-podagent agents.lock.yml file
  )
  opt.on('-p', '--project PROJECT', 'BigQuery project name') { |o| options[:project] = o }
  opt.on('-d', '--dataset DATASET', 'BigQuery dataset name') { |o| options[:dataset] = o }
end
parser.parse!

HERE = File.expand_path(File.dirname(__FILE__))
abort "Missing required param: project\n\n#{parser}" if options[:project].nil? || options[:project].empty?
abort "Missing required param: dataset\n\n#{parser}" if options[:dataset].nil? || options[:dataset].empty?
unless File.exists?("#{HERE}/.credentials.json")
  abort "You must add a .credentials.json file in the scripts directory!\n\n#{parser}"
end

bigquery = Google::Cloud::Bigquery.new(project: options[:project], keyfile: "#{HERE}/.credentials.json")
dataset = bigquery.dataset(options[:dataset])
abort "Dataset '#{options[:dataset]}' does not exist!" unless dataset

agent_tags = {}
puts 'getting latest database...'
print '  agents.lock.yml '
open('https://raw.githubusercontent.com/PRX/prx-podagent/master/db/agents.lock.yml', 'r') do |download|
  puts '-> downloaded'
  print '  parsing '
  agent_tags = YAML.load(download.read)['tags']
  puts "-> got #{agent_tags.count} name tags"
  abort "That's not enough" if agent_tags.count < 50 # should never decrease
end

print '  writing agentnames.json '
Dir.mkdir("#{HERE}/tmp") unless Dir.exists?("#{HERE}/tmp")
File.open("#{HERE}/tmp/agentnames.json", 'w') do |file|
  agent_tags.each do |id, tag|
    file << JSON.generate({agentname_id: id, tag: tag}) + "\n"
  end
end
print '-> gzipping '
`gzip -f #{HERE}/tmp/agentnames.json`
puts '-> done'

puts "checking #{options[:dataset]}.agentnames table..."
print '  dropping '
table = dataset.table('agentnames')
if table
  puts '-> dropped'
  table.delete
else
  puts '-> already gone'
end
print '  creating '
table = dataset.create_table 'agentnames' do |schema|
  schema.integer 'agentname_id', mode: :required
  schema.string 'tag'
end
puts '-> ok'

puts "inserting into #{options[:dataset]}.agentnames..."
print '  uploading agentnames.json job '
json = File.open("#{HERE}/tmp/agentnames.json.gz")
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
