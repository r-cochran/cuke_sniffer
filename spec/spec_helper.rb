# encoding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'cuke_sniffer'
require 'roxml'

include CukeSniffer::RuleConfig
include CukeSniffer::Constants

def build_file(lines, file_name = @file_name)
  file = File.open(file_name, "w")
  lines.each { |line| file.puts(line) }
  file.close
end

def delete_temp_files
  file_list = [
      @file_name,
      DEFAULT_OUTPUT_FILE_NAME + ".html",
      DEFAULT_OUTPUT_FILE_NAME + ".xml",
      DEFAULT_OUTPUT_FILE_NAME + ".pdf"
  ]
  file_list.each do |file_name|
    File.delete(file_name) if !file_name.nil? and File.exists?(file_name)
  end
end

def verify_rule(object, rule, count = 1)
  object.rules_hash[rule.phrase].should == count
  object.score.should >= rule.score
end

def verify_no_rule(object, rule)
  object.rules_hash[rule.phrase].should == nil
end

def remove_rules(rule_objects)
  rule_objects.each do |rule_object|
    rule_object.rules_hash = {}
    rule_object.score = 0
  end
end