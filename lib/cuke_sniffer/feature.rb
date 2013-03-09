module CukeSniffer
  class Feature < FeatureRulesEvaluator
    include CukeSniffer::Constants
    include CukeSniffer::RuleConfig

    SCENARIO_TITLE_REGEX = /#{COMMENT_REGEX}#{SCENARIO_TITLE_STYLES}(?<name>.*)/

    attr_accessor :background, :scenarios, :scenarios_score, :total_score

    def initialize(file_name)
      super(file_name)
      @scenarios = []
      @feature_rules_hash = {}
      @scenarios_score = 0
      @total_score = 0
      feature_lines = extract_feature_from_file(file_name)
      if feature_lines == []
        store_rule(FEATURE_RULES[:empty_feature])
      else
        split_feature(file_name, feature_lines)
        evaluate_score
      end
    end

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
      get_scenarios_score
      @total_score = score + @scenarios_score
    end

    def get_scenarios_score
      @scenarios_score += @background.score unless @background.nil?
      @scenarios.each do |scenario|
        @scenarios_score += scenario.score
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
