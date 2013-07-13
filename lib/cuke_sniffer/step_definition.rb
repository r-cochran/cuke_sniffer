require 'roxml'
module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Translates and evaluates Cucumber step definitions
  # Extends CukeSniffer::RulesEvaluator
  class StepDefinition < RuleTarget

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

    # string array: List of the parameters a step definition has
    attr_accessor :parameters

    # hash: Contains each nested step call a step definition has
    # * Key: location:line of the nested step
    # * Value: The step call that appears on the line
    attr_accessor :nested_steps

    # hash: Contains each call that is made to a step definition
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
          @parameters = matches[:parameters].split(/,\s*/).collect{|param| param.strip} if matches[:parameters]
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

    def condensed_call_list
      condensed_list = {}
      @calls.each do |call, step_string|
        condensed_list[step_string] ||= []
        condensed_list[step_string] << call
      end
      condensed_list
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

        if regex and !is_comment?(line)
          match = regex.match(line)
          nested_step_line = (@start_line + counter)
          @nested_steps[location.gsub(/:\d*$/, ":" + nested_step_line.to_s)] = match[:step_string].gsub("\\", "")
        end
        counter += 1
      end
    end

    def evaluate_score
    end
  end
end
