#!/usr/bin/env ruby

require 'cuke_sniffer'

if ARGV.include? "-h" or ARGV.include? "--help"
  puts "Welcome to CukeSniffer!
Calling CukeSniffer with no arguments will run it against the current directory.
Other Options for Running include:
  <feature_file_path>, <step_def_file_path> : Runs CukeSniffer against the specified paths.
  -o, --out html (name)                     : Runs CukeSniffer then outputs an html file in the current directory (with optional name).
  -h, --help                                : You get this lovely document."
  exit
end
@cuke_sniffer = nil
if File.directory?(ARGV[0]) and File.directory?(ARGV[1])
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

