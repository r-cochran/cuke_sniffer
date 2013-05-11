# encoding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'cuke_sniffer'
require 'roxml'

include CukeSniffer::RuleConfig

def build_file(lines)
  file = File.open(@file_name, "w")
  lines.each{|line| file.puts(line)}
  file.close
end