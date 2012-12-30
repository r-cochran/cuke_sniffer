class StepDefinition < RulesEvaluator
  attr_accessor :start_line, :regex, :code, :parameters, :calls, :nested_steps

  def initialize(location, raw_code)
    @parameters = []
    @calls = {}
    @nested_steps = {}
    @start_line = location.match(/:(?<line>\d*)/)[:line].to_i
    matches = STEP_DEFINITION_REGEX.match(raw_code.first)
    @regex = Regexp.new(matches[:step])

    end_match_index = (raw_code.size - 1) - raw_code.reverse.index("end")

    @parameters = matches[:parameters].split(",") unless matches[:parameters].nil?
    @code = raw_code[1...end_match_index]
    super(location)
    detect_nested_steps
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
          regex = END_COMPLEX_WITH_STEP_REGEX
          multi_line_step_flag = false
        when STEP_REGEX
          regex = STEP_REGEX if multi_line_step_flag
        when END_COMPLEX_STEP_REGEX
          multi_line_step_flag = false
        else
      end

      if regex
        match = regex.match(line)
        nested_step_line = (@start_line + counter)
        @nested_steps[@location.gsub(@start_line.to_s, nested_step_line.to_s)] = match[:step_string]
      end
      counter += 1
    end
  end

  def ==(comparison_object)
    comparison_object.location == @location
    comparison_object.regex == @regex
    comparison_object.code == code
    comparison_object.parameters == @parameters
    comparison_object.calls == @calls
    comparison_object.nested_steps == @nested_steps
  end

end