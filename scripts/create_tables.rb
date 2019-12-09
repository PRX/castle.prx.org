#!/usr/bin/env ruby
require 'optparse'
require 'google/cloud/bigquery'

options = {force: false}
parser = OptionParser.new do |opt|
  opt.banner = %q(Usage: create_tables.rb [options]

    Create the downloads and impressions tables for use by castle
  )
  opt.on('-p', '--project PROJECT', 'BigQuery project name') { |o| options[:project] = o }
  opt.on('-d', '--dataset DATASET', 'BigQuery dataset name') { |o| options[:dataset] = o }
  opt.on('-f', '--force', 'Force non-empty tables to drop') { |o| options[:force] = true }
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

#
# (1) dt_downloads table
#
puts "#{options[:dataset]}.dt_downloads table..."
if table = dataset.table('dt_downloads')
  abort "#{options[:dataset]}.dt_downloads already exists!" unless options[:force]
  abort "#{options[:dataset]}.dt_downloads is not empty!" unless table.rows_count == 0
  print '  dropping old -> '
  table.delete
  puts 'ok'
end
print '  creating new -> '
table = dataset.create_table 'dt_downloads' do |table|
  table.description = 'Dovetail downloads'
  table.time_partitioning_type = 'DAY'
  table.time_partitioning_field = 'timestamp'
  table.schema do |schema|
    schema.timestamp 'timestamp', mode: :required
    schema.string 'request_uuid', mode: :required

    # redirect data
    schema.integer 'feeder_podcast'
    schema.string 'feeder_episode'
    schema.string 'program'
    schema.string 'path'
    schema.string 'clienthash'
    schema.string 'digest'
    schema.integer 'ad_count'
    schema.boolean 'is_duplicate'
    schema.string 'cause'

    # request data
    schema.string 'remote_referrer'
    schema.string 'remote_agent'
    schema.string 'remote_ip'

    # derived data
    schema.integer 'agent_name_id'
    schema.integer 'agent_type_id'
    schema.integer 'agent_os_id'
    schema.integer 'city_geoname_id'
    schema.integer 'country_geoname_id'
    schema.string 'postal_code'
    schema.float 'latitude'
    schema.float 'longitude'

    # iab2 fields
    schema.boolean 'is_confirmed'
    schema.boolean 'is_bytes'
    schema.string 'url'
    schema.string 'listener_id'
    schema.string 'listener_episode'
    schema.string 'listener_session'
  end
end
puts 'ok'

#
# (2) dt_impressions table
#
puts "#{options[:dataset]}.dt_impressions table..."
if table = dataset.table('dt_impressions')
  abort "#{options[:dataset]}.dt_impressions already exists!" unless options[:force]
  abort "#{options[:dataset]}.dt_impressions is not empty!" unless table.rows_count == 0
  print '  dropping old -> '
  table.delete
  puts 'ok'
end
print '  creating new -> '
table = dataset.create_table 'dt_impressions' do |table|
  table.description = 'Dovetail impressions'
  table.time_partitioning_type = 'DAY'
  table.time_partitioning_field = 'timestamp'
  table.schema do |schema|
    schema.timestamp 'timestamp', mode: :required
    schema.string 'request_uuid', mode: :required

    # redirect data (redundant with the download)
    schema.integer 'feeder_podcast'
    schema.string 'feeder_episode'
    schema.boolean 'is_duplicate'
    schema.string 'cause'

    # adzerk data
    schema.integer 'ad_id'
    schema.integer 'campaign_id'
    schema.integer 'creative_id'
    schema.integer 'flight_id'

    # iab2 fields
    schema.boolean 'is_confirmed'
    schema.boolean 'is_bytes'
    schema.string 'digest'
    schema.string 'listener_session'
    schema.integer 'segment'
  end
end
puts 'ok'
