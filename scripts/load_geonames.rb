#!/usr/bin/env ruby
require 'optparse'
require 'google/cloud/bigquery'
require 'csv'
require 'zip'

options = {refresh: false}
parser = OptionParser.new do |opt|
  opt.banner = %q(Usage: load_geonames.rb [options]

    Load the geonames table from the maxmind geolite2 city database
  )
  opt.on('-p', '--project PROJECT', 'BigQuery project name') { |o| options[:project] = o }
  opt.on('-d', '--dataset DATASET', 'BigQuery dataset name') { |o| options[:dataset] = o }
  opt.on('-r', '--refresh', 'Force download to refresh the geolite csv') { |o| options[:refresh] = true }
end
parser.parse!

FIELDS = %w(geoname_id locale_code continent_code continent_name country_iso_code
  country_name subdivision_1_iso_code subdivision_1_name subdivision_2_iso_code
  subdivision_2_name city_name metro_code time_zone)

HERE = File.expand_path(File.dirname(__FILE__))
abort "Missing required param: project\n\n#{parser}" if options[:project].nil? || options[:project].empty?
abort "Missing required param: dataset\n\n#{parser}" if options[:dataset].nil? || options[:dataset].empty?
unless File.exists?("#{HERE}/.credentials.json")
  abort "You must add a .credentials.json file in the scripts directory!\n\n#{parser}"
end

bigquery = Google::Cloud::Bigquery.new(project: options[:project], keyfile: "#{HERE}/.credentials.json")
dataset = bigquery.dataset(options[:dataset])
abort "Dataset '#{options[:dataset]}' does not exist!" unless dataset

puts 'looking for geolite2 city csv...'
Dir.mkdir("#{HERE}/tmp") unless Dir.exists?("#{HERE}/tmp")
if !options[:refresh] && File.exists?("#{HERE}/tmp/GeoLite2-City-Locations-en.csv")
  puts "  already exists!"
else
  print '  GeoLite2-City-CSV.zip -> downloading '
  File.open("#{HERE}/tmp/GeoLite2-City-CSV.zip", 'wb') do |file|
    open('http://geolite.maxmind.com/download/geoip/database/GeoLite2-City-CSV.zip', 'rb') do |download|
      file.write(download.read)
    end
  end
  puts '-> unzipping ->'
  Zip::File.open("#{HERE}/tmp/GeoLite2-City-CSV.zip") do |zipfile|
    zipfile.each do |entry|
      if entry.name =~ /Locations-en/
        name = entry.name.split('/').last
        print "    #{name} -> "
        entry.extract("#{HERE}/tmp/#{name}")
        puts 'ok'
      end
    end
  end
  puts '  cleaning up '
  File.delete("#{HERE}/tmp/GeoLite2-City-CSV.zip")
  puts '-> ok'
end

puts 'formatting location csv...'
print '  reading GeoLite2-City-Locations-en.csv '
count = 0
File.open("#{HERE}/tmp/geonames.json", 'w') do |file|
  CSV.foreach("#{HERE}/tmp/GeoLite2-City-Locations-en.csv", headers: true) do |row|
    json = {}
    FIELDS.each { |name| json[name] = row[name] }
    file << JSON.generate(json) + "\n"
    count += 1
  end
end
puts "-> wrote #{count} rows"
print '  gzipping file '
`gzip -f #{HERE}/tmp/geonames.json`
puts '-> done'

puts "checking #{options[:dataset]}.geonames table..."
print '  dropping '
table = dataset.table('geonames')
if table
  puts '-> dropped'
  table.delete
else
  puts '-> already gone'
end
print '  creating '
table = dataset.create_table 'geonames' do |schema|
  schema.integer 'geoname_id', mode: :required
  schema.integer 'metro_code'
  (FIELDS - ['geoname_id', 'metro_code']).each do |name|
    schema.string name
  end
end
puts '-> ok'

puts "inserting into #{options[:dataset]}.geonames..."
print '  uploading geonames.json job (this could take awhile) '
json = File.open("#{HERE}/tmp/geonames.json.gz")
job = table.load(json, format: 'json', create: 'never', write: 'empty')
puts '-> done'
print '  running job '
job.wait_until_done!
if job.failed?
  puts '-> FAILED!'
  job.errors.each { |e| puts "    #{e}" }
else
  puts "-> loaded #{job.output_rows} rows"
end
