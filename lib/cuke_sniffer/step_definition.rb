require 'roxml'
module CukeSniffer
  class StepDefinition < RulesEvaluator
    include CukeSniffer::Constants
    include CukeSniffer::RuleConfig

    xml_accessor :start_line
    xml_accessor :regex
    xml_accessor :parameters, :as => [], :in => "parameters"
    xml_accessor :nested_steps, :as => {:key => 'location', :value => 'call'}, :in => "nested_steps"
    xml_accessor :calls, :as => {:key => 'location', :value => 'call'}, :in => "calls"
    xml_accessor :code, :as => [], :in => "code"

    SIMPLE_NESTED_STEP_REGEX = /steps\s"#{STEP_STYLES}(?<step_string>.*)"$/
    SAME_LINE_COMPLEX_STEP_REGEX = /^steps\s%(q|Q)?{#{STEP_STYLES}(?<step_string>.*)}$/
    START_COMPLEX_STEP_REGEX = /^steps\s%(q|Q)?\{\s*/
    END_COMPLEX_STEP_REGEX = /}$/
    START_COMPLEX_WITH_STEP_REGEX = /steps\s%(q|Q)?\{#{STEP_STYLES}(?<step_string>.*)$/
    END_COMPLEX_WITH_STEP_REGEX = /#{STEP_STYLES}(?<step_string>.*)}$/
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
          @parameters = matches[:parameters].split(",") unless matches[:parameters].nil?
        end
      end

      detect_nested_steps
      evaluate_score
    end

    def add_call(location, step_string)
      @calls[location] = step_string
    end

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
            multi_line_step_flag = true
            regex = START_COMPLEX_WITH_STEP_REGEX
          when START_COMPLEX_STEP_REGEX
            multi_line_step_flag = true
          when END_COMPLEX_WITH_STEP_REGEX
            if line =~ /[#]{.*}$/ && multi_line_step_flag
              regex = STEP_REGEX
            else
              regex = END_COMPLEX_WITH_STEP_REGEX
              multi_line_step_flag = false
            end
          when STEP_REGEX
            regex = STEP_REGEX if multi_line_step_flag
          when END_COMPLEX_STEP_REGEX
            multi_line_step_flag = false
          else
        end

        if regex
          index = 0
          while line.include?('#{') and index <= line.length
            index = line.index('#{')
            replace_string = ""
            while index <= line.length and line[index - 1] != "}"
              replace_string << line[index]
              index += 1
            end
            line.gsub!(replace_string, "variable")
          end

          match = regex.match(line)
          nested_step_line = (@start_line + counter)
          @nested_steps[location.gsub(/:\d*/, ":" + nested_step_line.to_s)] = match[:step_string]
        end
        counter += 1
      end
    end

    def condensed_call_list
      condensed_list = {}
      @calls.each{|call, step_string|
        condensed_list[step_string] ||= []
        condensed_list[step_string] << call
      }
      condensed_list
    end

    def ==(comparison_object)
      super(comparison_object)
      comparison_object.regex == regex
      comparison_object.code == code
      comparison_object.parameters == parameters
      comparison_object.calls == calls
      comparison_object.nested_steps == nested_steps
    end

    def evaluate_score
      super
      rule_no_code
      rule_too_many_parameters
      rule_nested_steps
      rule_recursive_nested_step
      rule_commented_code
      rule_lazy_debugging
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
