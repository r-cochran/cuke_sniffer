require 'roxml'
module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Translates and evaluates Cucumber step definitions
  class StepDefinition < RulesEvaluator

    xml_accessor :start_line
    xml_accessor :regex
    xml_accessor :parameters, :as => [], :in => "parameters"
    xml_accessor :nested_steps, :as => {:key => 'location', :value => 'call'}, :in => "nested_steps"
    xml_accessor :calls, :as => {:key => 'location', :value => 'call'}, :in => "calls"
    xml_accessor :code, :as => [], :in => "code"

    # int: Line on which a step definition starts
    attr_accessor :start_line

    # Regex: Regex that cucumber uses to match step calls
    attr_accessor :regex

    # string arra: List of the parameters a step definition has
    attr_accessor :parameters

    # hash:
    # * Key: location:line of the nested step
    # * Value: The step call that appears on the line
    attr_accessor :nested_steps

    # hash:
    # * Key: Location in which the step definition is called from
    # * Value: The step string that matched the regex
    # In the case of a fuzzy match it will be a regex of the
    # step call that was the inverse match of the regex translated
    # into a string.
    attr_accessor :calls

    # string array: List of all of the content between the regex and the end of the step definition.
    attr_accessor :code

    # location must be in the format of "file_path\file_name.rb:line_number"
    # raw_code is an array of strings that represents the step definition
    # must contain the regex line and its pairing end
    def initialize(location, raw_code)
      super(location)

      @parameters = []
      @calls = {}
      @nested_steps = {}
      @start_line = location.match(/:(?<line>\d*)$/)[:line].to_i

      end_match_index = (raw_code.size - 1) - raw_code.reverse.index("end")
      @code = raw_code[1...end_match_index]

      raw_code.each do |line|
        if line =~ STEP_DEFINITION_REGEX
          matches = STEP_DEFINITION_REGEX.match(line)
          @regex = Regexp.new(matches[:step])
          @parameters = matches[:parameters].split(/,\s*/) if matches[:parameters]
        end
      end

      detect_nested_steps
      evaluate_score
    end

    # Adds new location => step_string pairs to the calls hash
    def add_call(location, step_string)
      @calls[location] = step_string
    end

    def ==(comparison_object) # :nodoc:
      super(comparison_object) &&
      comparison_object.regex == regex &&
      comparison_object.code == code &&
      comparison_object.parameters == parameters &&
      comparison_object.calls == calls &&
      comparison_object.nested_steps == nested_steps
    end

    private

    SIMPLE_NESTED_STEP_REGEX = /steps?\s"#{STEP_STYLES}(?<step_string>.*)"$/ # :nodoc:
    START_COMPLEX_STEP_REGEX = /^steps?\s%(q|Q)?\{\s*/ # :nodoc:
    SAME_LINE_COMPLEX_STEP_REGEX = /#{START_COMPLEX_STEP_REGEX}#{STEP_STYLES}(?<step_string>.*)}$/ # :nodoc:
    END_COMPLEX_STEP_REGEX = /}$/ # :nodoc:
    START_COMPLEX_WITH_STEP_REGEX = /#{START_COMPLEX_STEP_REGEX}#{STEP_STYLES}(?<step_string>.*)$/ # :nodoc:
    END_COMPLEX_WITH_STEP_REGEX = /#{STEP_STYLES}(?<step_string>.*)}$/ # :nodoc:

    def detect_nested_steps
      multi_line_step_flag = false
      counter = 1
      @code.each do |line|
        regex = nil
        case line
          when SIMPLE_NESTED_STEP_REGEX
            regex = SIMPLE_NESTED_STEP_REGEX
          when SAME_LINE_COMPLEX_STEP_REGEX
            regex = SAME_LINE_COMPLEX_STEP_REGEX
          when START_COMPLEX_WITH_STEP_REGEX
            if line =~ /\}$/
              if line.include?('#{')
                reversed_line = line.reverse
                last_capture = reversed_line[0..reversed_line.index('#')].reverse
                if last_capture =~ /{.*}$/
                  multi_line_step_flag = true
                  regex = START_COMPLEX_WITH_STEP_REGEX
                else
                  regex = SAME_LINE_COMPLEX_STEP_REGEX
                end
              else
                regex = SAME_LINE_COMPLEX_STEP_REGEX
              end
            else
              multi_line_step_flag = true
              regex = START_COMPLEX_WITH_STEP_REGEX
            end
          when END_COMPLEX_WITH_STEP_REGEX
            if line =~ /[#]{.*}$/ && multi_line_step_flag
              regex = STEP_REGEX
            else
              regex = END_COMPLEX_WITH_STEP_REGEX
              multi_line_step_flag = false
            end
          when START_COMPLEX_STEP_REGEX
            multi_line_step_flag = true
          when STEP_REGEX
            regex = STEP_REGEX if multi_line_step_flag
          when END_COMPLEX_STEP_REGEX
            multi_line_step_flag = false
          else
        end

        if regex and is_comment?(line) == false
          match = regex.match(line)
          nested_step_line = (@start_line + counter)
          @nested_steps[location.gsub(/:\d*$/, ":" + nested_step_line.to_s)] = match[:step_string].gsub("\\", "")
        end
        counter += 1
      end
    end

    def condensed_call_list
      condensed_list = {}
      @calls.each { |call, step_string|
        condensed_list[step_string] ||= []
        condensed_list[step_string] << call
      }
      condensed_list
    end

    def evaluate_score
      super
      rule_no_code
      rule_too_many_parameters
      rule_nested_steps
      rule_recursive_nested_step
      rule_commented_code
      rule_lazy_debugging
      rule_pending
      rule_todo
      sleep_rules
    end

    def rule_todo
      code.each do |line|
        store_rule(RULES[:todo]) if line =~ /\#(TODO|todo)/
      end
    end

    def sleep_rules
      code.each do |line|
        match_data = line.match /^\s*sleep(\s|\()(?<sleep_time>.*)\)?/
        unless match_data.nil?
          sleep_value = match_data[:sleep_time].to_f
          store_rule(RULES[:small_sleep]) if sleep_value <= RULES[:small_sleep][:max]
          store_rule(RULES[:large_sleep]) if sleep_value > RULES[:large_sleep][:min]
        end
      end
    end

    def rule_pending
      code.each do |line|
        if line =~ /^\s*pending\s*$/
          store_rule(RULES[:pending])
          return
        end
      end
    end

    def rule_lazy_debugging
      code.each do |line|
        next if is_comment?(line)
        store_rule(RULES[:lazy_debugging]) if line.strip =~ /^(p|puts)( |\()('|"|%(q|Q)?\{)/
      end
    end

    def rule_no_code
      store_rule(RULES[:no_code]) if code.empty?
    end

    def rule_too_many_parameters
      rule = RULES[:too_many_parameters]
      store_rule(rule) if parameters.size >= rule[:max]
    end

    def rule_nested_steps
      store_rule(RULES[:nested_step]) unless nested_steps.empty?
    end

    def rule_recursive_nested_step
      nested_steps.each_value do |nested_step|
        store_rule(RULES[:recursive_nested_step]) if nested_step =~ regex
      end
    end

    def rule_commented_code
      code.each do |line|
        store_rule(RULES[:commented_code]) if is_comment?(line)
      end
    end

  end
end
