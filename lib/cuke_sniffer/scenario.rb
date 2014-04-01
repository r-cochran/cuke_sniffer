module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2014 Robert Cochran
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

    def commented_examples
      @examples_table.select do |example|
        is_comment?(example)
      end
    end

    def get_steps(step_start)
      if step_start != "*"
        regex = /^\s*#{step_start}/
      else
        regex = /^\s*[*]/
      end
      @steps.select do |step|
        step =~ regex
      end
    end

    private

    def split_scenario(scenario)
      ranges = define_ranges(scenario)
      split_tag_list(ranges[:tags])
      split_name_and_type(ranges[:name].join(" "))
      split_scenario_body(ranges[:body])
      split_examples(ranges[:examples]) unless ranges[:examples].nil?
    end

    def define_ranges(scenario)
      ranges = {}
      index = 0
      index += 1 until index >= scenario.length or scenario[index] =~ SCENARIO_TITLE_STYLES
      ranges[:tags] = scenario[0...index]

      start_index = index
      index += 1 until index >= scenario.length or scenario[index].match STEP_REGEX or scenario[index].include?("Examples:")
      ranges[:name] = scenario[start_index...index]

      start_index = index
      index += 1 until index >= scenario.length or scenario[index].include?("Examples:")
      ranges[:body] = scenario[start_index...index]

      ranges[:examples] = scenario[index + 1..scenario.size] if index < scenario.length and scenario[index].include?("Examples:")
      ranges
    end

    def split_tag_list(list_of_tag_lines)
      list_of_tag_lines.each do |line|
        update_tag_list(line)
      end
    end

    def split_name_and_type(name_section)
      match = name_section.match(SCENARIO_TITLE_STYLES)
      @type = match[:type] unless match.nil?
      create_name(name_section, SCENARIO_TITLE_STYLES)
    end

    def split_scenario_body(scenario_body)
      extract_steps(scenario_body)
      extract_inline_tables(scenario_body)
    end

    def extract_steps(scenario_body)
      scenario_body.each do |line|
        next if line =~ /^\|.*\|/ or line.empty? or line.match(STEP_REGEX).nil?
        @steps << line
      end
    end

    def extract_inline_tables(scenario_body)
      index = 0
      while index < scenario_body.size
        if scenario_body[index] =~ /^\|.*\|/
          start_index = index
          while index < scenario_body.size and scenario_body[index] =~ /^\|.*\|/
            index += 1
          end
          @inline_tables[scenario_body[start_index-1]] = scenario_body[start_index..index]
        end
        index += 1
      end
    end

    def split_examples(examples_section)
      remove_examples_declaration(examples_section).each do |line|
        next if line.include?("Examples:")
        @examples_table << line if line =~ /#{COMMENT_REGEX}\|.*\|/
      end
    end

    def remove_examples_declaration(examples_section)
      return_section = []
      index = 0
      while index < examples_section.size
        index += 2 if(examples_section[index].include?("Examples:"))
        return_section << examples_section[index]
        index += 1
      end
      return_section
    end
  end
end
