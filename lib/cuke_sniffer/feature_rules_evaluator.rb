require 'cuke_sniffer/constants'
require 'cuke_sniffer/rule_target'

module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2014 Robert Cochran
  # License::   Distributes under the MIT License
  # Parent class for Feature and Scenario objects
  # holds shared attributes and rules.
  # Extends CukeSniffer::RuleTarget
  class FeatureRuleTarget < RuleTarget

    # string array: Contains all tags attached to a Feature or Scenario
    attr_accessor :tags

    # string: Name of the Feature or Scenario
    attr_accessor :name

    # Location must be in the format of "file_path\file_name.rb:line_number"
    def initialize(location)
      @name = ""
      @tags = []
      super(location)
    end

    def == (comparison_object) # :nodoc:
      super(comparison_object) &&
      comparison_object.name == name &&
      comparison_object.tags == tags
    end

    def is_comment_and_tag?(line)
      true if line =~ /^\#.*\@.*$/
    end

    private

    def create_name(line, filter)
      line.gsub!(/#{COMMENT_REGEX}#{filter}/, "")
      line.strip!
      @name += " " unless @name.empty? or line.empty?
      @name += line
    end

    def update_tag_list(line)
      comment_start = (line =~ /([^@\w]#)|(^#)/)

      if comment_start
        line[0...comment_start].split.each { |single_tag| @tags << single_tag }
        @tags << line[comment_start..line.length].strip
      else
        line.split.each { |single_tag| @tags << single_tag }
      end
    end

  end
end

