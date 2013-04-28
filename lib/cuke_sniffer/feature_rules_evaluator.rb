require 'cuke_sniffer/constants'
require 'cuke_sniffer/rule_config'
require 'cuke_sniffer/rules_evaluator'

module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Parent class for Feature and Scenario objects
  # holds shared attributes and rules.
  # Extends CukeSniffer::RulesEvaluator
  class FeatureRulesEvaluator < RulesEvaluator

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
      super(comparison_object)
      comparison_object.name == name
      comparison_object.tags == tags
    end

    private

    def create_name(line, filter)
      line.gsub!(/#{COMMENT_REGEX}#{filter}/, "")
      line.strip!
      @name += " " unless @name.empty? or line.empty?
      @name += line
    end

    def update_tag_list(line)
      if TAG_REGEX.match(line) && !is_comment?(line)
        line.scan(TAG_REGEX).each { |tag| @tags << tag[0] }
      else
        @tags << line.strip unless line.empty?
      end
    end

    def evaluate_score
      super
      cls_name = self.class.to_s.gsub('CukeSniffer::', '')
      rule_too_many_tags(cls_name)
      rule_no_description(cls_name)
      rule_numbers_in_name(cls_name)
      rule_long_name(cls_name)
      rule_commas_in_description(cls_name)
      rule_comment_after_tag(cls_name)
    end

    def rule_too_many_tags(type)
      rule = RULES[:too_many_tags]
      store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type)) if tags.size >= rule[:max]
    end

    def rule_no_description(type)
      rule = RULES[:no_description]
      store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type)) if name.empty?
    end

    def rule_numbers_in_name(type)
      rule = RULES[:numbers_in_description]
      store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type)) if name =~ /\d/
    end

    def rule_long_name(type)
      rule = RULES[:long_name]
      store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type)) if name.size >= rule[:max]
    end

    def rule_commas_in_description(type)
      rule = RULES[:commas_in_description]
      store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type)) if name.include?(',')
    end

    def rule_comment_after_tag(type)
      rule = RULES[:comment_after_tag]
      store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type)) if tags.grep(/^\s*\#/) != []
    end
  end
end

