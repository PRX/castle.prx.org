#!/usr/bin/env ruby
require 'optparse'
require 'csv'
require 'openssl'
require 'base64'
require 'ipaddr'
require 'google/cloud/storage'
require 'maxmind_geoip2'
require 'securerandom'

STDOUT.sync = true

options = {local: false}
parser = OptionParser.new do |opt|
  opt.banner = %q(Usage: convert_schema.rb [options]

    Download dumped csv files, convert schema, and upload
  )
  opt.on('-p', '--project PROJECT', 'BigQuery project name') { |o| options[:project] = o }
  opt.on('-d', '--dataset DATASET', 'BigQuery dataset name') { |o| options[:dataset] = o }
  opt.on('-b', '--bucket BUCKET', 'Storage bucket name') { |o| options[:bucket] = o }
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
IN_PATH = "migrate_downloads/#{options[:dataset]}"
OUT_PATH = "migrate_downloads/#{options[:dataset]}_out"

storage = Google::Cloud::Storage.new(project: options[:project], keyfile: KEYFILE)
bucket = storage.bucket(options[:bucket])
abort "Bucket '#{options[:bucket]}' does not exist!" unless bucket

IP_LOOKUP_CACHE = {}
def lookip(literal_ip)
  clean_ip = (literal_ip || '').split(',').map(&:strip).reject(&:empty?).reject{|i| i == 'unknown'}.first
  masked_ip = begin
    a = IPAddr.new(clean_ip)
    if a.ipv6?
      a.mask('ffff:ffff:ffff:ffff:ffff:ffff:ffff:0')
    else
      a.mask('255.255.255.0')
    end
  rescue IPAddr::InvalidAddressError
    nil
  end
  if masked_ip.nil?
    [nil, {}]
  else
    [masked_ip, MaxmindGeoIP2.locate(clean_ip) || {}]
  end
end
def sha256(str)
  abort "You must set a SECRET_KEY" if ENV['SECRET_KEY'].nil? || ENV['SECRET_KEY'].empty?
  digest = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), ENV['SECRET_KEY'], str)
  Base64.encode64(digest).strip.gsub('+', '-').gsub('/', '_').gsub('=', '')
end

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

# (2) look for unprocessed days
puts 'Looking for csv files'
print "  scanning gs://#{options[:bucket]}/#{IN_PATH} -> "
page = bucket.files(prefix: "#{IN_PATH}/")
in_files = [].concat(page)
while page.token
  page = bucket.files(prefix: "#{IN_PATH}/", token: page.token)
  in_files.concat(page)
end
in_days = in_files.map{|f| f.name.gsub("#{IN_PATH}/", '').split('/').first}.uniq
puts "#{in_files.count} files, #{in_days.count} days"
print "  scanning gs://#{options[:bucket]}/#{OUT_PATH} -> "
out_files = bucket.files(prefix: "#{OUT_PATH}/")
out_days = out_files.map{|f| f.name.match(/(\d{4})(\d{2})(\d{2})/).to_a.drop(1).join('-')}.uniq
puts "#{out_files.count} files, #{out_days.count} days"
print "  finding missing days -> "
todos = (in_days - out_days).sort.reverse
puts "#{todos.count} todo"
date = todos.first
print "  getting lock for #{date} -> "
lock_uuid = SecureRandom.uuid
lock_path = "#{OUT_PATH}/downloads_#{date.gsub('-', '')}.lock"
bucket.create_file StringIO.new(lock_uuid), lock_path
lock = bucket.file(lock_path).download()
if lock.string == lock_uuid
  puts 'ok'
else
  abort 'someone stole it from us!!!'
end

# (3) download source csv files
puts "Downloading #{date} dump files..."
todo_infiles = []
FileUtils.mkdir_p("#{HERE}/tmp/#{IN_PATH}/#{date}")
bucket.files(prefix: "#{IN_PATH}/#{date}/").each do |file|
  print "  #{File.basename(file.name)} (#{file.size / 1000 / 1000} mb) -> "
  path = "#{HERE}/tmp/#{IN_PATH}/#{date}/#{File.basename(file.name)}"
  todo_infiles << path
  if File.exists?(path) && File.size(path) == file.size
    puts 'already downloaded'
  else
    file.download(path)
    puts 'done'
  end
end

# (4) the real work (slow)
puts "Converting #{date} schemas..."
FileUtils.mkdir_p("#{HERE}/tmp/#{OUT_PATH}")
CSV.open("#{HERE}/tmp/#{OUT_PATH}/downloads_#{date.gsub('-','')}.csv", 'w') do |dest_csv|
  dest_csv << %w(
    timestamp request_uuid
    feeder_podcast feeder_episode program path
    clienthash digest ad_count is_duplicate cause
    remote_referrer remote_agent remote_ip
    agent_name_id agent_type_id agent_os_id
    city_geoname_id country_geoname_id postal_code latitude longitude
  )
  todo_infiles.each do |path|
    print "  #{File.basename(path)} -> "
    count = 0
    CSV.foreach(path, headers: true) do |row|
      clienthash = sha256(row['path'] + row['remote_ip'] + row['remote_agent'])
      referer = nil
      masked_ip, loc = lookip(row['remote_ip'])
      dest_csv << [
        row['timestamp'], row['request_uuid'],
        row['feeder_podcast'], row['feeder_episode'], row['program'], row['path'],
        clienthash, row['digest'], row['ad_count'], row['is_duplicate'], row['cause'],
        referer, row['remote_agent'], masked_ip,
        row['agent_name_id'], row['agent_type_id'], row['agent_os_id'],
        loc['city_geoname_id'], loc['country_geoname_id'], loc['postal_code'], loc['latitude'], loc['longitude']
      ]
      count += 1
      print "(#{count / 100000 / 10.0}m) " if count % 100000 == 0
    end
    puts "#{count} rows"
  end
end

# (5) gzip and re-upload
puts "Uploading #{date} out-file"
name = "downloads_#{date.gsub('-','')}.csv"
path = "#{HERE}/tmp/#{OUT_PATH}/#{name}"
puts "  #{File.basename(path)}"
print "  gzipping #{File.size(path) / 1000 / 1000} mb -> "
`gzip #{path}`
puts "#{File.size(path + '.gz') / 1000 / 1000} mb"
print "  uploading to gs:#{options[:bucket]}/#{OUT_PATH}/#{name}.gz -> "
bucket.create_file "#{path}.gz", "#{OUT_PATH}/#{name}.gz"
puts "ok"
print "  unlocking -> "
bucket.file(lock_path).delete()
puts "ok"
print "  cleanup -> "
FileUtils.rm_rf("#{HERE}/tmp/migrate_downloads")
puts "ok"
