require 'cuke_sniffer/constants'
require 'cuke_sniffer/rule_config'
require 'cuke_sniffer/feature_rules_evaluator'
require 'cuke_sniffer/scenario'

module CukeSniffer
  class Feature < FeatureRulesEvaluator
    include CukeSniffer::Constants
    include CukeSniffer::RuleConfig

    attr_accessor :background, :scenarios, :feature_rules_hash

    def initialize(file_name)
      super(file_name)
      @scenarios = []
      @feature_rules_hash = {}
      split_feature(file_name)
      evaluate_score
    end

    def split_feature(file_name)
      feature_lines = []

      feature_file = File.open(file_name)
      feature_file.each_line { |line| feature_lines << line }
      feature_file.close

      index = 0
      until feature_lines[index].match FEATURE_NAME_REGEX
        update_tag_list(feature_lines[index])
        index += 1
      end

      until index >= feature_lines.length or feature_lines[index].match TAG_REGEX or feature_lines[index].match SCENARIO_TITLE_REGEX
        create_name(feature_lines[index], "Feature:")
        index += 1
      end

      scenario_title_found = false
      index_of_title = nil
      code_block = []
      until index >= feature_lines.length
        if scenario_title_found and (feature_lines[index].match TAG_REGEX or feature_lines[index].match SCENARIO_TITLE_REGEX)
          add_scenario_to_feature(code_block, index_of_title)
          scenario_title_found = false
          code_block = []
        end
        code_block << feature_lines[index].strip
        if feature_lines[index].match SCENARIO_TITLE_REGEX
          scenario_title_found = true
          index_of_title = "#{file_name}:#{index + 1}"
        end
        index += 1
      end
      #TODO - Last scenario falling through above logic, needs a fix (code_block related)
      add_scenario_to_feature(code_block, index_of_title) unless code_block==[]
    end

    def add_scenario_to_feature(code_block, index_of_title)
      scenario = CukeSniffer::Scenario.new(index_of_title, code_block)
      if scenario.type == "Background"
        @background = scenario
      else
        @scenarios << scenario
      end
    end

    def ==(comparison_object)
      super(comparison_object)
      comparison_object.scenarios == scenarios
    end

    def evaluate_score
      super
      rule_no_scenarios
      rule_too_many_scenarios
      rule_background_with_no_scenarios
      rule_background_with_one_scenario
      @feature_rules_hash = @rules_hash.clone
      include_sub_scores(@background) unless @background.nil?
      include_scenario_scores
    end

    def include_sub_scores(sub_class)
      @score += sub_class.score
      sub_class.rules_hash.each_key do |rule_descriptor|
        rules_hash[rule_descriptor] ||= 0
        rules_hash[rule_descriptor] += sub_class.rules_hash[rule_descriptor]
      end
    end

    def include_scenario_scores
      scenarios.each do |scenario|
        include_sub_scores(scenario)
      end
    end

    def rule_no_scenarios
      store_rule(FEATURE_RULES[:no_scenarios]) if @scenarios.empty?
    end

    def rule_too_many_scenarios
      rule = FEATURE_RULES[:too_many_scenarios]
      store_rule(rule) if @scenarios.size >= rule[:max]
    end

    def rule_background_with_no_scenarios
      store_rule( FEATURE_RULES[:background_with_no_scenarios]) if @scenarios.empty? and !@background.nil?
    end

    def rule_background_with_one_scenario
      store_rule(FEATURE_RULES[:background_with_one_scenario]) if @scenarios.size == 1 and !@background.nil?
    end

  end
end
