#!/usr/bin/env ruby
require 'cuke_sniffer'

if ARGV.include? "-h" or ARGV.include? "--help"
  puts HELP_CMD_TEXT
  exit
end

@cuke_sniffer = nil
if (ARGV[0] != nil and File.directory?(ARGV[0])) and (ARGV[1] != nil and File.directory?(ARGV[1]))
  @cuke_sniffer = CukeSniffer.new(ARGV[0], ARGV[1])
else
  @cuke_sniffer = CukeSniffer.new
end

def print_results
  puts @cuke_sniffer.output_results
end

if ARGV.include? "--out" or ARGV.include? "-o"
  index = ARGV.index("--out")
  index ||= ARGV.index("-o")
  out_type = ARGV[index + 1]
  case out_type
    when "html"
      @cuke_sniffer.output_html
    else
      print_results
  end
else
  print_results
end

puts "Completed Sniffing."
