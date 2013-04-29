module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # This class is a representation of the cucumber objects
  # Background, Scenario, Scenario Outline
  #
  # Extends CukeSniffer::FeatureRulesEvaluator
  class Scenario < FeatureRulesEvaluator

    xml_accessor :start_line
    xml_accessor :steps, :as => [], :in => "steps"
    xml_accessor :examples_table, :as => [], :in => "examples"

    # int: Line on which the scenario begins
    attr_accessor :start_line

    # String: Background, Scenario, Scenario Outline
    attr_accessor :type

    # string array: List of each step call in a scenario
    attr_accessor :steps

    # hash:
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
      evaluate_score
    end

    def ==(comparison_object) # :nodoc:
      super(comparison_object) &&
      comparison_object.steps == steps &&
      comparison_object.examples_table == examples_table
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
          until index >= scenario.length or scenario[index] =~ STEP_REGEX
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
          @examples_table << scenario[index] unless scenario[index].empty?
          index += 1
        end
      end
    end

    def get_step_order
      order = []
      @steps.each { |line|
        next if is_comment?(line)
        match = line.match(STEP_REGEX)
        order << match[:style] unless match.nil?
      }
      order
    end

    def evaluate_score
      if type == "Background"
        rule_numbers_in_name(type)
        rule_long_name(type)
        rule_tagged_background(type)
      else
        super
        rule_step_order
      end

      rule_empty_scenario
      rule_too_many_steps
      rule_invalid_first_step
      rule_asterisk_step
      rule_commented_step
      rule_implementation_words
      rule_date_used_in_step
      rule_one_word_step
      rule_multiple_given_when_then
      rule_commented_tag
      evaluate_outline_scores if type == "Scenario Outline"
    end

    def evaluate_outline_scores
      rule_no_examples_table
      rule_no_examples
      rule_one_example
      rule_too_many_examples
      rule_commented_example
    end

    def rule_multiple_given_when_then
      step_order = get_step_order
      rule = RULES[:multiple_given_when_then]
      phrase = rule[:phrase].gsub(/{.*}/, type)
      %w(Given When Then).each { |type| store_updated_rule(rule, phrase) if step_order.count(type) > 1 }
    end

    def rule_one_word_step
      @steps.each do |step|
        store_rule(RULES[:one_word_step]) if step.split.count == 2
      end
    end

    def rule_empty_scenario
      rule = RULES[:no_steps]
      store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type)) if @steps.empty?
    end

    def rule_too_many_steps
      rule = RULES[:too_many_steps]
      store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type)) if @steps.size >= rule[:max]
    end

    def rule_step_order
      step_order = get_step_order.uniq
      %w(But * And).each { |type| step_order.delete(type) }
      store_rule(RULES[:out_of_order_steps]) unless step_order == %w(Given When Then) or step_order == %w(When Then)
    end

    def rule_invalid_first_step
      first_step = get_step_order.first
      rule = RULES[:invalid_first_step]
      store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type)) if %w(And But).include?(first_step)
    end

    def rule_asterisk_step
      get_step_order.count('*').times { store_rule(RULES[:asterisk_step]) }
    end

    def rule_commented_step
      @steps.each do |step|
        store_rule(RULES[:commented_step]) if is_comment?(step)
      end
    end

    def rule_implementation_words
      rule = RULES[:implementation_word]
      @steps.each do |step|
        next if is_comment?(step)
        rule[:words].each do |word|
          store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, word)) if step.include?(word)
        end
      end
    end

    def rule_date_used_in_step
      @steps.each do |step|
        store_rule(RULES[:date_used]) if step =~ DATE_REGEX
      end
    end

    def rule_no_examples_table
      store_rule(RULES[:no_examples_table]) if @examples_table.empty?
    end

    def rule_no_examples
      store_rule(RULES[:no_examples]) if @examples_table.size == 1
    end

    def rule_one_example
      store_rule(RULES[:one_example]) if @examples_table.size == 2 and !is_comment?(@examples_table[1])
    end

    def rule_too_many_examples
      store_rule(RULES[:too_many_examples]) if (@examples_table.size - 1) >= 8
    end

    def rule_commented_example
      @examples_table.each do |example|
        store_rule(RULES[:commented_example]) if is_comment?(example)
      end
    end

    def rule_tagged_background(type)
      rule = RULES[:background_with_tag]
      store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type)) if tags.size > 0
    end

    def rule_commented_tag
      tags.each do |tag|
        store_rule(RULES[:commented_tag]) if tag =~ /#.*/
      end
    end
  end
end
