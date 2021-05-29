#!/usr/bin/env ruby
require 'optparse'
require 'google/cloud/bigquery'

options = {force: false}
parser = OptionParser.new do |opt|
  opt.banner = %q(Usage: 0002_add_vast.rb [options]

    Update the dt_impressions table schema to add VAST fields
  )
  opt.on('-p', '--project PROJECT', 'BigQuery project name') { |o| options[:project] = o }
  opt.on('-d', '--dataset DATASET', 'BigQuery dataset name') { |o| options[:dataset] = o }
end
parser.parse!

abort "Missing required param: project\n\n#{parser}" if options[:project].nil? || options[:project].empty?
abort "Missing required param: dataset\n\n#{parser}" if options[:dataset].nil? || options[:dataset].empty?

CREDENTIALS = File.expand_path(File.join(File.dirname(__FILE__), '..', '.credentials.json'))
unless File.exists?(CREDENTIALS)
  abort "You must add a .credentials.json file in the scripts directory!\n\n#{parser}"
end

puts "Using project: #{options[:project]}, dataset: #{options[:dataset]}"

bigquery = Google::Cloud::Bigquery.new(project: options[:project], keyfile: CREDENTIALS)

dataset = bigquery.dataset(options[:dataset])
abort "Dataset '#{options[:dataset]}' does not exist!" unless dataset

table = dataset.table('dt_impressions')
abort "#{options[:dataset]}.dt_impressions doesn't exist - go back and create it!" unless table

abort "#{options[:dataset]}.dt_impressions columns already added" if table.headers.include?(:vast_price_model)

puts "Update #{options[:dataset]}.dt_impressions table..."

print '  adding columns -> '
table.schema do |schema|
  schema.string 'vast_advertiser' # AdsWizz
  schema.string 'vast_ad_id' # AdsWizz1
  schema.string 'vast_creative_id' # 1
  schema.numeric 'vast_price_value' # 1.00
  schema.string 'vast_price_currency' # USD, EUR
  schema.string 'vast_price_model' # CPM
end
puts 'ok'
