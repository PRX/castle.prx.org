#!/usr/bin/env ruby
require 'optparse'
require 'csv'
require 'google/cloud/bigquery'
require 'google/cloud/storage'
require 'maxmind_geoip2'

options = {force: false, local: false}
parser = OptionParser.new do |opt|
  opt.banner = %q(Usage: create_tables.rb [options]

    Transfer and convert downloads table to new dt_downloads schema
  )
  opt.on('-t', '--time TIME', 'Day to run this for YYYY-MM-DD') { |o| options[:time] = o }
  opt.on('-p', '--project PROJECT', 'BigQuery project name') { |o| options[:project] = o }
  opt.on('-d', '--dataset DATASET', 'BigQuery dataset name') { |o| options[:dataset] = o }
  opt.on('-b', '--bucket BUCKET', 'Storage bucket name') { |o| options[:bucket] = o }
  opt.on('-f', '--force', 'Force re-querying source table') { |o| options[:force] = true }
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
GS_BUCKET = "gs://#{options[:bucket]}"
GS_PATH = "migrate_downloads/#{options[:dataset]}/#{options[:time]}"
OUT_FILE = "dt_downloads_#{options[:time].gsub('-', '')}.csv"
OUT_PATH = "migrate_downloads/#{options[:dataset]}_out/#{OUT_FILE}"
TMP_TABLE = "downloads_tmp_#{options[:time].gsub('-', '')}"

bigquery = Google::Cloud::Bigquery.new(project: options[:project], keyfile: KEYFILE)
dataset = bigquery.dataset(options[:dataset])
abort "Dataset '#{options[:dataset]}' does not exist!" unless dataset
tmp_table = dataset.table(TMP_TABLE) || dataset.create_table(TMP_TABLE)

storage = Google::Cloud::Storage.new(project: options[:project], keyfile: KEYFILE)
bucket = storage.bucket(options[:bucket])
abort "Bucket '#{options[:bucket]}' does not exist!" unless bucket

# (1) download maxmind db
unless File.exists?("#{HERE}/tmp/GeoLite2-City.mmdb")
  puts "Downloading GeoLite2-City.tar.gz..."
  FileUtils.mkdir_p("#{HERE}/tmp")
  File.open("#{HERE}/tmp/GeoLite2-City.tar.gz", 'wb') do |file|
    open('http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz', 'rb') do |download|
      file.write(download.read)
    end
  end
  print '  unzipping -> '
  `tar -xzf #{HERE}/tmp/GeoLite2-City.tar.gz --strip 1 -C #{HERE}/tmp/`
  puts 'ok'
end
MaxmindGeoIP2.file "#{HERE}/tmp/GeoLite2-City.mmdb"
MaxmindGeoIP2.locale 'en'
MAXMINDCACHE = {}
def lookip(unclean_ip)
  ip = (unclean_ip || '').split(',').map(&:strip).reject(&:empty?).reject{|i| i == 'unknown'}.first
  if MAXMINDCACHE[ip]
    MAXMINDCACHE[ip]
  else
    loc = MaxmindGeoIP2.locate(ip) || {}
    MAXMINDCACHE[ip] = [
      loc['city_geoname_id'],
      loc['country_geoname_id'],
      nil, nil, nil,
      loc['postal_code'],
      loc['latitude'],
      loc['longitude'],
      nil
    ]
  end
end

# (2) export source table
unless options[:force] || bucket.files(prefix: GS_PATH).any?
  puts "Exporting from #{options[:dataset]}.downloads.#{options[:time]}..."
  print "  querying to #{options[:dataset]}.downloads_tmp_migrate -> "
  sql = "SELECT * FROM downloads WHERE _PARTITIONTIME = '#{options[:time]}'"
  job = dataset.query_job(sql, table: tmp_table, large_results: true, create: 'needed', write: 'truncate')
  job.wait_until_done!
  if job.failed?
    puts 'FAILED!'
    job.errors.each { |e| puts "    #{e}" }
  else
    puts "done #{job.bytes_processed / 1000 / 1000} mb"
  end
  print "  dumping to #{GS_BUCKET}/#{GS_PATH}/downloads_*.csv -> "
  job = tmp_table.extract_job("#{GS_BUCKET}/#{GS_PATH}/downloads_*.csv")
  job.wait_until_done!
  if job.failed?
    puts 'FAILED!'
    job.errors.each { |e| puts "    #{e}" }
  else
    puts "dumped #{job.destinations_file_counts.map(&:to_i).inject(:+)} files"
  end
end
tmp_table.delete

# (3) download and process the files
puts "Processing dump files..."
FileUtils.rm_rf("#{HERE}/tmp/migrate_downloads")
FileUtils.mkdir_p("#{HERE}/tmp/migrate_downloads")
CSV.open("#{HERE}/tmp/migrate_downloads/#{OUT_FILE}", 'w') do |dest_csv|
  dest_csv << %w(
    timestamp request_uuid
    feeder_podcast feeder_episode program path digest ad_count is_duplicate cause
    remote_referrer remote_agent
    agent_name_id agent_type_id agent_os_id
    geoname_id registered_country_geoname_id represented_country_geoname_id is_anonymous_proxy is_satellite_provider postal_code latitude longitude accuracy_radius
  )

  total = 0
  bucket.files(prefix: GS_PATH).all.each do |file|
    print "  downloading #{File.basename(file.name)} (#{file.size / 1000 / 1000} mb) -> "
    file.download "#{HERE}/tmp/migrate_downloads/#{File.basename(file.name)}"
    print 'processing -> '

    count = 0
    CSV.foreach("#{HERE}/tmp/migrate_downloads/#{File.basename(file.name)}", headers: true) do |row|
      total += 1
      count += 1
      dest_csv << [
        row['timestamp'], row['request_uuid'],
        row['feeder_podcast'], row['feeder_episode'], row['program'], row['path'],
        row['digest'], row['ad_count'], row['is_duplicate'], row['cause'],
        nil, row['remote_agent'],
        row['agent_name_id'], row['agent_type_id'], row['agent_os_id']
      ].concat(lookip(row['remote_ip']))
    end
    FileUtils.rm_rf("#{HERE}/tmp/migrate_downloads/#{File.basename(file.name)}")
    puts "done #{count}"
  end

  puts "Uploading migrated #{options[:time]} data..."
  size = File.size("#{HERE}/tmp/migrate_downloads/#{OUT_FILE}")
  print "  uploading #{total} lines (#{size / 1000 / 1000} mb) -> "
  bucket.create_file "#{HERE}/tmp/migrate_downloads/#{OUT_FILE}", OUT_PATH
  puts "gs://#{options[:bucket]}/#{OUT_PATH}"
end
