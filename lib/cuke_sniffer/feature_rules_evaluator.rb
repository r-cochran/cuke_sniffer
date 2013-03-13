require 'cuke_sniffer/constants'
require 'cuke_sniffer/rule_config'
require 'cuke_sniffer/rules_evaluator'

module CukeSniffer
  class FeatureRulesEvaluator < RulesEvaluator
    include CukeSniffer::Constants
    include CukeSniffer::RuleConfig
    
    attr_accessor :tags, :name

    def initialize(location)
      @name = ""
      @tags = []
      super(location)
    end

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
      store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type))  if name.size >= rule[:max]
    end

    def == (comparison_object)
      super(comparison_object)
      comparison_object.name == name
      comparison_object.tags == tags
    end

  end
end
