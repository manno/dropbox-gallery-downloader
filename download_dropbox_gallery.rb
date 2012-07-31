#!/usr/bin/ruby
require 'optparse'
require 'fileutils'
require 'open-uri'
require 'nokogiri'
require 'pp'

DEBUG = false

OPTIONS = {
  :gallery_url => '',
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

if OPTIONS[:gallery_url].empty? and ARGV[0]
  OPTIONS[:gallery_url] = ARGV[0]
end

if OPTIONS[:destination_path] == '.' and ARGV[1]
  OPTIONS[:destination_path] = ARGV[1]
end

FileUtils.mkdir_p( OPTIONS[:destination_path] ) unless File.directory?( OPTIONS[:destination_path] )

doc = Nokogiri::HTML(open(OPTIONS[:gallery_url]))

results = []
doc.css('a.thumb-link').each do |a|
  results << a['href']
end

results.map! { |r| 
  { url: "#{r}?dl=1" , filename: r.gsub!(/.*\//, '') }
}
max = results.length
n = 1

results.each do |r|
  puts "downloading #{r[:filename]} [#{n}/#{max}]"
  `wget -k -c -q "#{r[:url]}" -O "#{r[:filename]}"` unless DEBUG
  n = n + 1
end
