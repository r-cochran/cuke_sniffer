module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # This class is a representation of the cucumber objects
  # Background, Scenario, Scenario Outline
  #
  # Extends CukeSniffer::FeatureRulesEvaluator
  class Scenario < FeatureRuleTarget

    xml_accessor :start_line
    xml_accessor :steps, :as => [], :in => "steps"
    xml_accessor :examples_table, :as => [], :in => "examples"

    # int: Line on which the scenario begins
    attr_accessor :start_line

    # string: The type of scenario
    # Background, Scenario, Scenario Outline
    attr_accessor :type

    # string array: List of each step call in a scenario
    attr_accessor :steps

    # hash: Keeps each location and content of an inline table
    # * Key: Step string the inline table is attached to
    # * Value: Array of all of the lines in the table
    attr_accessor :inline_tables

    # string array: List of each example row in a scenario outline
    attr_accessor :examples_table

    # Location must be in the format of "file_path\file_name.rb:line_number"
    # Scenario must be a string array containing everything from the first tag to the last example table
    # where applicable.
    def initialize(location, scenario)
      super(location)
      @start_line = location.match(/:(?<line>\d*)$/)[:line].to_i
      @steps = []
      @inline_tables = {}
      @examples_table = []
      split_scenario(scenario)
    end

    def ==(comparison_object) # :nodoc:
      super(comparison_object) &&
      comparison_object.steps == steps &&
      comparison_object.examples_table == examples_table
    end

    def get_step_order
      order = []
      @steps.each do |line|
        next if is_comment?(line)
        match = line.match(STEP_REGEX)
        order << match[:style] unless match.nil?
      end
      order
    end

    def outline?
      type === 'Scenario Outline'
    end

    private

    def split_scenario(scenario)
      index = 0
      until index >= scenario.length or scenario[index] =~ SCENARIO_TITLE_STYLES
        update_tag_list(scenario[index])
        index += 1
      end

      until index >= scenario.length or scenario[index].match STEP_REGEX or scenario[index].include?("Examples:")
        match = scenario[index].match(SCENARIO_TITLE_STYLES)
        @type = match[:type] unless match.nil?
        create_name(scenario[index], SCENARIO_TITLE_STYLES)
        index += 1
      end

      until index >= scenario.length or scenario[index].include?("Examples:")
        if scenario[index] =~ /^\|.*\|/
          step = scenario[index - 1]
          @inline_tables[step] = []
          until index >= scenario.length or scenario[index] =~ /(#{STEP_REGEX}|^\s*Examples:)/
            @inline_tables[step] << scenario[index]
            index += 1
          end
        else
          @steps << scenario[index] if scenario[index] =~ STEP_REGEX
          index += 1
        end
      end

      if index < scenario.length and scenario[index].include?("Examples:")
        index += 1
        until index >= scenario.length
          index += 2 if scenario[index].include?("Examples:")
          @examples_table << scenario[index] if scenario[index] =~ /#{COMMENT_REGEX}\|.*\|/
          index += 1
        end
      end
    end
  end
end
