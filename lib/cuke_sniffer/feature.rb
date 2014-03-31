require 'cuke_sniffer/feature_rules_evaluator'

require 'cuke_sniffer/scenario'

module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Handles feature files and disassembles and evaluates
  # its components.
  # Extends CukeSniffer::FeatureRulesEvaluator
  class Feature < FeatureRuleTarget

    xml_accessor :scenarios, :as => [CukeSniffer::FeatureRuleTarget], :in => "scenarios"

    SCENARIO_TITLE_REGEX = /#{COMMENT_REGEX}#{SCENARIO_TITLE_STYLES}(?<name>.*)/ # :nodoc:

    # Scenario: The background of a Feature, created as a Scenario object
    attr_accessor :background

    # Scenario array: A list of all scenarios contained in a feature file
    attr_accessor :scenarios

    # int: Total score from all of the scenarios contained in the feature
    attr_accessor :scenarios_score

    # int: Total score of the feature and its scenarios
    attr_accessor :total_score

    # String array: A list of all the lines in a feature file
    attr_accessor :feature_lines

    # file_name must be in the format of "file_path\file_name.feature"
    def initialize(file_name)
      super(file_name)
      @type = "Feature"
      @scenarios = []
      @scenarios_score = 0
      @total_score = 0
      @feature_lines = IO.readlines(file_name)
      split_feature(file_name, feature_lines) unless @feature_lines == []
    end

    def ==(comparison_object) # :nodoc:
      super(comparison_object) &&
          comparison_object.scenarios == scenarios
    end

    def update_score
      @scenarios_score += @background.score unless @background.nil?
      @scenarios.each { |scenario| @scenarios_score += scenario.score }
      @total_score = @scenarios_score + @score
    end

    private

    def split_feature(file_name, feature_lines)
      index = 0
      until index >= feature_lines.length or feature_lines[index].match /Feature:\s*(?<name>.*)/
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
        if scenario_title_found and feature_lines[index].match SCENARIO_TITLE_REGEX
          not_our_code = []
          code_block.reverse.each do |line|
            break if line =~ /#{SCENARIO_TITLE_STYLES}|#{STEP_STYLES}|^\|.*\||Examples:/
            not_our_code << line
          end

          if not_our_code.empty?
            add_scenario_to_feature(code_block, index_of_title)
          else
            add_scenario_to_feature(code_block[0...(-1 * not_our_code.length)], index_of_title)
          end
          scenario_title_found = false
          code_block = not_our_code.reverse
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
  end
end
