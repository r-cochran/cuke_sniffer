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
      @scenario_model = determine_model(scenario)

      split_scenario(@scenario_model)
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
      @scenario_model.is_a?(CukeModeler::Outline)
    end

    def commented_examples
      get_comments.select do |comment|
        comment =~ /\|.*\|/
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

    def get_comments
      related_comments = []

      scenario_start_line = determine_start_line
      next_scenario_start_line = determine_end_line

      @scenario_model.get_ancestor(:feature_file).comments.each do |comment_model|
        if comment_model.source_line > scenario_start_line
          if (comment_model.source_line < next_scenario_start_line) || (next_scenario_start_line == -1)
            related_comments << comment_model.text
          end
        end
      end


      related_comments
    end

    def commented_step?(comment)
      comment =~ CukeSniffer::Constants::STEP_STYLES
    end


    private


    def determine_model(source)

      # May have been given a model object directly (from a CukeSniffer::Feature)
      return source if source.is_a?(CukeModeler::Model)

      model = nil

      begin
        # Try a feature model
        model = CukeModeler::Feature.new(source.join("\n"))

        # May have to remodel if it turns out to not be a feature.
        raise 'Source was not for a feature.' unless (model.parsing_data['type'].nil?) || (model.parsing_data[:type] == :Feature)

        # Grab the, presumably only, relevant model out of it
        model = model.background || model.tests.first
      rescue
        begin
          # Try a background model
          model = CukeModeler::Background.new(source.join("\n"))

          # May have to remodel if it turns out to not be a background.
          raise 'Source was not for a background.' unless (model.parsing_data['type'] == 'background') || (model.parsing_data[:type] == :Background)
        rescue
          begin
            # Try an outline model
            model = CukeModeler::Outline.new(source.join("\n"))

            # May have to remodel if it turns out to not be a scenario.
            raise 'Source was not for an outline.' unless (model.parsing_data['type'] == 'scenario_outline') || (model.parsing_data[:type] == :ScenarioOutline)
          rescue
            # Try a scenario model (done last because an outline can be confused for a scenario but not the other way around)
            model = CukeModeler::Scenario.new(source.join("\n"))
          end
        end
      end


      model
    end

    def determine_start_line
      @scenario_model.source_line
    end

    def determine_end_line
      related_feature = @scenario_model.get_ancestor(:feature)
      tests = related_feature.tests
      tests.unshift(related_feature.background) if related_feature.background

      if @scenario_model == tests.last
        # Everything else in the file belongs to this test
        -1
      else
        # Everything until the next test belongs to this test
        tests[tests.index(@scenario_model) + 1].source_line
      end
    end

    def split_scenario(model)
      split_tag_list(model)
      split_name_and_type(model)
      split_scenario_body(model)
      split_examples(model) if model.is_a?(CukeModeler::Outline)
    end

    def split_tag_list(model)
      update_tag_list(model)
    end

    def split_name_and_type(model)
      case
        when model.is_a?(CukeModeler::Background)
          @type = 'Background'
        when model.is_a?(CukeModeler::Scenario)
          @type = 'Scenario'
        when model.is_a?(CukeModeler::Outline)
          @type = 'Scenario Outline'
      end

      create_name(model)
    end

    def split_scenario_body(model)
      extract_steps(model)
      extract_inline_tables(model)
    end

    def extract_steps(model)
      model.steps.each do |step|
        @steps << "#{step.keyword} #{step.text}"
      end
    end

    def extract_inline_tables(model)
      model.steps.each do |step|
        if step.block && step.block.is_a?(CukeModeler::Table)
          @inline_tables["#{step.keyword} #{step.text}"] = step.block.rows.collect { |row| row.to_s }
        end
      end
    end

    def split_examples(outline_model)
      # Gather the parameter row of the first table + argument rows for all tables
      outline_model.examples.each do |example|
        @examples_table << example.argument_rows.collect { |row| row.to_s }
      end

      @examples_table.unshift(outline_model.examples.first.parameter_row.to_s) unless outline_model.examples.empty?

      @examples_table.flatten!
    end
  end
end
