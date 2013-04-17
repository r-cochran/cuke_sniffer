module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License

  # Handles feature files and disassembles and evaluates
  # its components.
  class Feature < FeatureRulesEvaluator

    xml_accessor :scenarios, :as => [CukeSniffer::FeatureRulesEvaluator], :in => "scenarios"

    SCENARIO_TITLE_REGEX = /#{COMMENT_REGEX}#{SCENARIO_TITLE_STYLES}(?<name>.*)/ # :nodoc:

    # Scenario: The background of a Feature, created as a Scenario object
    attr_accessor :background

    # Scenario array: A list of all scenarios contained in a feature file
    attr_accessor :scenarios

    # int: Total score from all of the scenarios contained in the feature
    attr_accessor :scenarios_score

    # int: Total score of the feature and its scenarios
    attr_accessor :total_score

    # file_name must be in the format of "file_path\file_name.feature"
    def initialize(file_name)
      super(file_name)
      @scenarios = []
      @scenarios_score = 0
      @total_score = 0
      feature_lines = extract_feature_from_file(file_name)
      if feature_lines == []
        store_rule(RULES[:empty_feature])
      else
        split_feature(file_name, feature_lines)
        evaluate_score
      end
    end

    def ==(comparison_object) # :nodoc:
      super(comparison_object)
      comparison_object.scenarios == scenarios
    end

    private

    def extract_feature_from_file(file_name)
      feature_lines = []
      feature_file = File.open(file_name)
      feature_file.each_line { |line| feature_lines << line }
      feature_file.close
      feature_lines
    end

    def split_feature(file_name, feature_lines)
      index = 0
      until feature_lines[index].match /Feature:\s*(?<name>.*)/
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
      feature_applied_scenario_rules(scenario)
      if scenario.type == "Background"
        @background = scenario
      else
        @scenarios << scenario
      end
    end

    def evaluate_score
      super
      rule_no_scenarios
      rule_too_many_scenarios
      rule_background_with_no_scenarios
      rule_background_with_one_scenario
      rule_scenario_same_tag
      get_scenarios_score
      @total_score = score + @scenarios_score
    end

    def feature_applied_scenario_rules(scenario)
      rule_feature_same_tags(scenario)
    end

    def rule_feature_same_tags(scenario)
      rule = RULES[:feature_same_tag]
      tags.each{|tag|
        scenario.store_updated_rule(rule, rule[:phrase] + tag) if scenario.tags.include?(tag)
      }
    end

    def rule_scenario_same_tag
      rule = RULES[:scenario_same_tag]
      unless scenarios.empty?
        base_tag_list = scenarios.first.tags
        scenarios.each do |scenario|
          base_tag_list.each do |tag|
            base_tag_list.delete(tag) unless scenario.tags.include?(tag)
          end
        end
        base_tag_list.each do |tag|
          store_updated_rule(rule, rule[:phrase] + tag)
        end
      end
    end

    def get_scenarios_score
      @scenarios_score += @background.score unless @background.nil?
      @scenarios.each do |scenario|
        @scenarios_score += scenario.score
      end
    end

    def rule_no_scenarios
      store_rule(RULES[:no_scenarios]) if @scenarios.empty?
    end

    def rule_too_many_scenarios
      rule = RULES[:too_many_scenarios]
      store_rule(rule) if @scenarios.size >= rule[:max]
    end

    def rule_background_with_no_scenarios
      store_rule( RULES[:background_with_no_scenarios]) if @scenarios.empty? and !@background.nil?
    end

    def rule_background_with_one_scenario
      store_rule(RULES[:background_with_one_scenario]) if @scenarios.size == 1 and !@background.nil?
    end

  end
end
