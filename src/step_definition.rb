class StepDefinition
  attr_accessor :location, :regex, :code, :parameters, :calls, :nested_steps, :score, :rules_hash

  STEP_DEFINITION_REGEX = /^(Given|When|Then|And|Or|\*)\s\/(?<step>.+)\/\sdo\s?(\|(?<parameters>.*)\|)?$/x
  SIMPLE_NESTED_STEP_REGEX = /^steps\s"(Given|When|Then|And|Or|\*)\s(?<step_string>.*)"/x
  SAME_LINE_COMPLEX_STEP_REGEX = /^steps\s%{(Given|When|Then|And|Or|\*)\s(?<step_string>.*)}/x
  START_COMPLEX_STEP_REGEX = /^steps\s%{\s*$/
  STEP_REGEX = /^(Given|When|Then|And|Or|\*)\s(?<step_string>.*)/x
  END_COMPLEX_STEP_REGEX = /^}$/
  START_COMPLEX_WITH_STEP_REGEX = /^steps\s%{(Given|When|Then|And|Or|\*)\s(?<step_string>.*)/x
  END_COMPLEX_WITH_STEP_REGEX = /^(Given|When|Then|And|Or|\*)\s(?<step_string>.*)}$/x

  def initialize(location, raw_code)
    @location = location

    @parameters = []
    @calls = {}
    @nested_steps = []
    @score = 0
    @rules_hash = {}

    matches = STEP_DEFINITION_REGEX.match(raw_code.first)
    @regex = Regexp.new(matches[:step])

    @parameters = matches[:parameters].split(",") unless matches[:parameters].nil?
    @code = raw_code[1...raw_code.length-1]
    detect_nested_steps
    evaluate_score
  end

  def add_call(location, step_string)
    @calls[location] = step_string
  end

  def detect_nested_steps
    multi_line_step_flag = false
    @code.each { |line|

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
          multi_line_step_flag= false
        when STEP_REGEX
          if multi_line_step_flag
            regex = STEP_REGEX
          end
        when END_COMPLEX_STEP_REGEX
          multi_line_step_flag = false
        else
      end

      unless regex.nil?
        match = regex.match(line)
        @nested_steps << match[:step_string]
        next
      end
    }
  end

  def ==(comparison_object)
    comparison_object.location == @location
    comparison_object.regex == @regex
    comparison_object.code == code
    comparison_object.parameters == @parameters
    comparison_object.calls == @calls
    comparison_object.nested_steps == @nested_steps
  end

  def evaluate_score
    @score = 1
    @rules_hash = {"Rule Descriptor" => 1}
  end

end