require 'cuke_sniffer/feature_rules_evaluator'

require 'cuke_sniffer/scenario'

module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2014 Robert Cochran
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
      @feature_model = CukeModeler::FeatureFile.new(file_name).feature
      @type = "Feature"
      @scenarios = []
      @scenarios_score = 0
      @total_score = 0
      @feature_lines = IO.readlines(file_name)

      if @feature_model
        build_tags
        build_name
        add_scenarios_to_feature if (@feature_model.background || @feature_model.tests.any?)
      end
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


    def build_tags
      update_tag_list(@feature_model)
    end

    def build_name
      create_name(@feature_model)
    end

    def add_scenarios_to_feature
      file_name = @feature_model.parent_model.path

      if @feature_model.background
        location = "#{file_name}:#{@feature_model.background.source_line}"
        @background = CukeSniffer::Scenario.new(location, @feature_model.background)
      end

      @feature_model.tests.each do |test_model|
        location = "#{file_name}:#{test_model.source_line}"
        @scenarios << CukeSniffer::Scenario.new(location, test_model)
      end
    end
  end
end
