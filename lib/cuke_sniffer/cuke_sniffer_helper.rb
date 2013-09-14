module CukeSniffer
  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Static class used for aiding cuke_sniffer in various tasks
  class CukeSnifferHelper

    # Iterates over the passed features list and returns all steps found in scenarios and backgrounds.
    def self.extract_steps_from_features(features)
      steps = {}
      features.each do |feature|
        steps.merge! extract_scenario_steps(feature.background) unless feature.background.nil?
        feature.scenarios.each do |scenario|
          if scenario.type == "Scenario Outline"
            steps.merge! extract_scenario_outline_steps(scenario)
          else
            steps.merge! extract_scenario_steps(scenario)
          end
        end
      end
      steps
    end

    # Iterates over the passed features list and returns all scenarios and backgrounds found.
    def self.get_all_scenarios(features)
      scenarios = []
      features.each do |feature|
        scenarios << feature.background unless feature.background.nil?
        scenarios << feature.scenarios
      end
      scenarios.flatten
    end

    # Grabs the values from an example without the bars
    def self.extract_variables_from_example(example)
      example = example[example.index('|')..example.length]
      example.split(/\s*\|\s*/) - [""]
    end

    # Creates a step call from the details of an example table
    def self.build_updated_step_from_example(step, variable_list, row_variables)
      new_step = step.dup
      variable_list.each do |variable|
        if step.include? variable
          table_variable_to_insert = row_variables[variable_list.index(variable)]
          table_variable_to_insert ||= ""
          new_step.gsub!("<#{variable}>", table_variable_to_insert)
        end
      end
      new_step
    end

    # Creates a hash of steps with the build up example step calls.
    def self.extract_scenario_outline_steps(scenario)
      steps = {}
      examples = scenario.examples_table
      return {} if examples.empty?
      variable_list = extract_variables_from_example(examples.first)
      (1...examples.size).each do |example_counter|
        #TODO Abstraction needed for this regex matcher (constants?)
        next if examples[example_counter] =~ /^\#.*$/
        row_variables = extract_variables_from_example(examples[example_counter])
        step_counter = 1
        scenario.steps.each do |step|
          step_line = scenario.start_line + step_counter
          location = "#{scenario.location.gsub(/\d+$/, step_line.to_s)}(Example #{example_counter})"
          steps[location] = build_updated_step_from_example(step, variable_list, row_variables)
          step_counter += 1
        end
      end
      steps
    end

    # Returns all steps found in a scenario
    def self.extract_scenario_steps(scenario)
      steps_hash = {}
      counter = 1
      scenario.steps.each do |step|
        location = scenario.location.gsub(/:\d*$/, ":#{scenario.start_line + counter}")
        steps_hash[location] = step
        counter += 1
      end
      steps_hash
    end

    # Builds a list of rule objects out of a hash. See CukeSniffer::RulesConfig for hash example.
    def self.build_rules(rules)
      return [] if rules.nil?
      rules.collect do |key, value|
        CukeSniffer::CukeSnifferHelper.build_rule(value)
      end
    end

    # Builds rule object out of a hash. See CukeSniffer::RulesConfig for hash example.
    def self.build_rule(rule_hash)
      rule = CukeSniffer::Rule.new
      rule.phrase = rule_hash[:phrase]
      rule.score = rule_hash[:score]
      rule.enabled = rule_hash[:enabled]
      conditional_keys = rule_hash.keys - [:phrase, :score, :enabled, :targets, :reason]
      conditions = {}
      conditional_keys.each do |key|
        conditions[key] = (rule_hash[key].kind_of? Array) ? Array.new(rule_hash[key]) : rule_hash[key]
      end
      rule.conditions = conditions
      rule.reason = rule_hash[:reason]
      rule.targets = rule_hash[:targets]
      rule
    end

    # Returns a list of all nested step calls found in a step definition.
    def self.extract_steps_from_step_definitions(step_definitions)
      steps = {}
      step_definitions.each do |definition|
        definition.nested_steps.each do |location, step|
          steps[location] = step
        end
      end
      steps
    end

    # Returns a fuzzy match for a step definition for cataloging steps.
    def self.convert_steps_with_expressions(steps_with_expressions)
      step_regex_hash = {}
      steps_with_expressions.each do |step_location, step_value|
        modified_step = step_value.gsub(/\#{[^}]*}/, '.*')
        next if modified_step == '.*'
        step_regex_hash[step_location] = Regexp.new('^' + modified_step + '$')
      end
      step_regex_hash
    end

    # Extracts all possible step calls from the passed features and step definitions.
    def self.get_all_steps(features, step_definitions)
      feature_steps = CukeSniffer::CukeSnifferHelper.extract_steps_from_features(features)
      step_definition_steps = CukeSniffer::CukeSnifferHelper.extract_steps_from_step_definitions(step_definitions)
      feature_steps.merge step_definition_steps
    end

    # Applies all possible fuzzy calls to a step definition.
    def self.catalog_possible_dead_steps(step_definitions, steps_with_expressions)
      step_definitions.each do |step_definition|
        next unless step_definition.calls.empty?
        regex_as_string = step_definition.regex.to_s.gsub(/\(\?-mix:\^?/, "").gsub(/\$\)$/, "")
        steps_with_expressions.each do |step_location, step_value|
          if regex_as_string =~ step_value
            step_definition.add_call(step_location, step_value)
          end
        end
      end
      step_definitions
    end

    # Returns a list of all step definitions with a capture group
    def self.get_steps_with_expressions(steps)
      steps_with_expressions = {}
      steps.each do |step_location, step_value|
        if step_value =~ /\#{.*}/
          steps_with_expressions[step_location] = step_value
        end
      end
      steps_with_expressions
    end

  end
end