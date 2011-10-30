#!/usr/bin/ruby
require 'optparse'
require 'fileutils'
require 'open-uri'
require 'nokogiri'
require 'pp'

def unescape(string)
  string.gsub(/((?:\\x[0-9a-fA-F]{2})+)/n) do
    [$1.delete("\\\\x")].pack('H*')
  end
end

PHOTO_MATCH = /'([^']*)': ["']([^"']*)['"],/
DEBUG = false

OPTIONS = {
  :gallery_url => '',
  :format => 'original',
  :destination_path => '.',
}

ARGV.options do |opt|
  opt.on('-u', '--url=GALLERYURL', String, 'dropbox public gallery url') { |v| OPTIONS[:gallery_url] = v }
  opt.on('-d', '--destination=OPTIONAL', String, 'destination directory') { |v| OPTIONS[:destination_path] = v }
  opt.on('-f', '--format=OPTIONAL', String, 'download (thumbnail|large|extralarge|original) photos') { |v| OPTIONS[:format] = v }
  opt.on("-h", "--help", "Show this help message.") { puts opt; exit }
  opt.parse!
end
(print ARGV.options; exit) unless ARGV[0]

if OPTIONS[:gallery_url].empty? and not ARGV[0].empty?
  OPTIONS[:gallery_url] = ARGV[0]
end

if OPTIONS[:destination_path] == '.' and not ARGV[1].empty?
  OPTIONS[:destination_path] = ARGV[1]
end

FileUtils.mkdir_p( OPTIONS[:destination_path] ) unless File.directory?( OPTIONS[:destination_path] )

doc = Nokogiri::HTML(open(OPTIONS[:gallery_url]))

results = []
doc.css('script').each do |script|
  photo = {}
  script.content.scan( PHOTO_MATCH ) { |k,v|
    if k == 'filename'
      results << photo unless photo.empty?
      photo = {}
    end
    photo[k] = v
  }
end

urls = results.select { |r| r.has_key?( OPTIONS[:format] ) }
max = urls.length
n = 1

urls.each do |r|
  if r.has_key?( OPTIONS[:format] )
    filename = unescape( r['filename'] )
    url = unescape( r[OPTIONS[:format]] )
    puts "downloading #{filename} [#{n}/#{max}]"
    `wget -k -c -q "#{url}" -O "#{ File.join(OPTIONS[:destination_path], filename) }"` unless DEBUG
    n = n + 1
  end
end
