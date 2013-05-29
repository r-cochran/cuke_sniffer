require 'spec_helper'

describe CukeSniffer::StepDefinition do

  it "should retain the passed location of the step after initialization" do
    raw_code = ["When /^the second number is 1$/ do",
                "@second_number = 1",
                "end"]
    location = "path/path/path/my_steps.rb:1"
    step_definition = CukeSniffer::StepDefinition.new(location, raw_code)
    step_definition.location.should == location
  end

  it "should accept a simple step definition with no parameters it should divide that code into a regular expression, parameters, and code" do
    raw_code = ["When /^the second number is 1$/ do",
                "@second_number = 1",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.regex.should == /^the second number is 1$/
    step_definition.parameters.should == []
    step_definition.code.should == ["@second_number = 1"]
  end

  it "should accept a simple step definition with parameters it should divide that code into a regular expression, parameters, and code" do
    raw_code = ["Given /^the first number is \"([^\"]*)\"$/ do |first_number|",
                "@second_number = 1",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.regex.should == /^the first number is "([^"]*)"$/
    step_definition.parameters.should == ["first_number"]
    step_definition.code.should == ["@second_number = 1"]
  end

  it 'is not impacted by excess whitespace around parameters' do
    raw_code = ["Given /a step/ do | param_1 ,  param_2,param_3    |",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.parameters.should == ['param_1','param_2','param_3']
  end

  it "should add passed call locations (file + line) and their matched step call to a record hash" do
    raw_code = ["Given /^the first number is \"([^\"]*)\"$/ do |first_number|",
                "@second_number = 1",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    location = "myFile.rb:line 3"
    step_string = "the first number is \"1\""
    step_definition.add_call(location, step_string)
    step_definition.calls.should == {location => step_string}
  end

  it "should evaluate 1 complex nested step with open and close on the same line" do
    nested_step = "the first number is \"1\""
    raw_code = ["Given /^the first number is 1$/ do |first_number|",
                "steps \"And #{nested_step}\"",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {"location:2" => nested_step}
  end

  it "should evaluate 1 complex nested step with open on the same line" do
    nested_step = "the first number is \"1\""
    raw_code = ["Given /^the first number is 1$/ do |first_number|",
                "steps %Q{And #{nested_step}",
                "}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {"location:2" => nested_step}
  end

  it "should capture a nested step with an expression" do
    nested_step = "this step has an \#{expression}"
    raw_code = ["Given /^This step has a passed in \"parameter\"$/ do |expression|",
                "steps %Q{And #{nested_step}}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {"location:2" => nested_step}
  end

  it "should evaluate 1 complex nested step with the close on the same line" do
    nested_step = "the first number is \"1\""
    raw_code = ["Given /^the first number is 1$/ do |first_number|",
                "steps %Q{",
                "And #{nested_step}}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {"location:3" => nested_step}
  end

  it "should evaluate 1 complex nested steps on its own line" do
    nested_step = "the first number is \"1\""
    raw_code = ["Given /^the first number is 1$/ do |first_number|",
                "steps %Q{",
                "And #{nested_step}",
                "}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {"location:3" => nested_step}
  end

  it "should evaluate many complex nested step with steps on their own line" do
    nested_step = "the first number is \"1\""
    raw_code = ["Given /^the first number is 1$/ do |first_number|",
                "steps %Q{",
                "And #{nested_step}",
                "And #{nested_step}",
                "}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {"location:3" => nested_step, "location:4" => nested_step}
  end

  it "should evaluate many complex nested step with steps on the start line, their own line, and the close line" do
    nested_step = "the first number is \"1\""
    raw_code = ["Given /^the first number is 1$/ do |first_number|",
                "steps %{And #{nested_step}",
                "And #{nested_step}",
                "And #{nested_step}",
                "And #{nested_step}}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {
        "location:2" => nested_step,
        "location:3" => nested_step,
        "location:4" => nested_step,
        "location:5" => nested_step
    }
  end

  it "should evaluate the step definition and the score should be greater than 0" do
    raw_code = ["Given /^step with no code$/ do",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.score.should > 0
  end

  it "should evaluate the step definition and then update a list of rules/occurrences" do
    raw_code = ["Given /^step with no code$/ do",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.rules_hash.should_not == {}
  end

  it "should have a score and rule list immediately after being created" do
    raw_code = ["Given /^step with no code$/ do",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.score.should > 0
    step_definition.rules_hash.should_not == {}
  end

  it "should evaluate multiple sets of complex nested steps across multiple lines" do
    nested_step_set_one = "the first number is \"1\""
    nested_step_set_two = "the second number is \"55\""
    raw_code = ["Given /^the first number is 1$/ do |first_number|",
                "steps %Q{",
                "And #{nested_step_set_one}",
                "And #{nested_step_set_one}",
                "}",
                "#commented code",
                "steps %Q{",
                "And #{nested_step_set_two}",
                "And #{nested_step_set_two}",
                "And #{nested_step_set_two}",
                "}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {"location:3" => nested_step_set_one, "location:4" => nested_step_set_one, "location:8" => nested_step_set_two, "location:9" => nested_step_set_two, "location:10" => nested_step_set_two, }
  end

  it "should determine if it is above the scenario threshold" do
    raw_code = ["Given /^step with no code$/ do",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["StepDefinition"]
    CukeSniffer::Constants::THRESHOLDS["StepDefinition"] = 2
    step_definition.good?.should == false
    CukeSniffer::Constants::THRESHOLDS["StepDefinition"] = start_threshold
  end

  it "should determine if it is below the step definition threshold" do
    raw_code = ["Given /^step with no code$/ do",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["StepDefinition"]
    CukeSniffer::Constants::THRESHOLDS["StepDefinition"] = 200
    step_definition.good?.should == true
    CukeSniffer::Constants::THRESHOLDS["StepDefinition"] = start_threshold
  end

  it "should determine the percentage of problems compared to the step definition threshold" do
    raw_code = ["Given /^step with no code$/ do",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["StepDefinition"]
    CukeSniffer::Constants::THRESHOLDS["StepDefinition"] = 2
    step_definition.score = 3
    step_definition.problem_percentage.should == (3.0/2.0)
    CukeSniffer::Constants::THRESHOLDS["StepDefinition"] = start_threshold
  end

  it "should capture a nested step correctly that is defined in a string literal with spaces between the { and the start of the step" do
    raw_code = ["Given /^my step$/ do",
                "steps %{ And I am calling a nested step}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.values.include?("I am calling a nested step").should be_true
  end

  it "should capture a nested step correctly that are on the same line as the closing of a string literal" do
    raw_code = ["Given /^my step$/ do",
                "steps %{",
                "And I am calling a nested step}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.values.include?("I am calling a nested step").should be_true
  end

  it "should capture a nested step correctly that are on the same line as the opening of a string literal" do
    raw_code = ["Given /^my step$/ do",
                "steps %{And I am calling a nested step}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.values.include?("I am calling a nested step").should be_true
  end

  it "should capture a nested step correctly that uses a } to close a variable use and is not the true end of the strings" do
    raw_code = ["Given /^my step$/ do",
                "steps %{And I am a nested step that uses a \#{variable}",
                "And this is the true end of the nested step}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.values.include?("this is the true end of the nested step").should be_true
  end

  it "should capture nested steps when the 'step' call is used with simple string" do
    raw_code = ["Given /^step nested step call$/ do",
                "step \"And my nested step call\"",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.values.include?("my nested step call").should be_true
  end

  it "should capture nested steps when the 'step' call is used with string literal" do
    raw_code = ["Given /^step nested step call$/ do",
                "step %{And my nested step call}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.values.include?("my nested step call").should be_true
  end

  it "should capture nested steps used in conditional logic" do
    raw_code = ["Given /^step nested step call$/ do",
                "if steps %{And my nested step call}",
                "fail",
                "end",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.values.include?("my nested step call").should be_true
  end

  it "should ignore commented lines when looking for nested steps" do
    raw_code = ["Given /^step nested step call$/ do",
                "#      steps %{And my nested step call}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {}
  end

  it "should disregard nested steps that have \\ in their statements" do
    raw_code = ["Given /^step nested step call$/ do",
                "  steps %{And my nested step call says hello to \\\"John\\\"}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {"location:2" => 'my nested step call says hello to "John"'}
    step_definition.nested_steps.values[0].should =~ /my nested step call says hello to ".*"/
  end

end

describe "StepDefinitionRules" do

  def validate_rule(step_definition, rule)
    phrase = rule[:phrase]
    step_definition.rules_hash.include?(phrase).should be_true
    step_definition.rules_hash[phrase].should > 0
    step_definition.score.should >= rule[:score]
  end

  it "should punish Step Definitions with no code" do
    raw_code = ["Given /^step with no code$/ do",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:no_code])
  end

  it "should punish Step Definitions with too many parameters" do
    rule = RULES[:too_many_parameters]
    parameters = ""
    rule[:max].times { |n| parameters += "param#{n}, " }

    raw_code = ["Given /^step with many parameters$/ do |#{parameters}|", "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, rule)
  end

  it "should punish Step Definitions that have nested steps" do
    raw_code = ["Given /^step with nested step call$/ do", "steps \"And I am a nested step\"", "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:nested_step])
  end

  it "should punish Step Definitions that have recursive nested steps" do
    raw_code = ["Given /^step with recursive nested step call$/ do", "steps \"And step with recursive nested step call\"", "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:recursive_nested_step])
  end

  it "should punish each commented line in a Step Definition" do
    raw_code = ["Given /^step with comments$/ do",
                "#steps \"And step with recursive nested step call\"",
                "#steps \"And step with recursive nested step call\"",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:commented_code])
  end

  it "should punish each instance of lazy debugging (puts with single quotes)" do
    raw_code = ["Given /^step with comments$/ do",
                "puts 'debug statement'",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:lazy_debugging])
  end

  it "should punish each instance of lazy debugging (puts with double quotes)" do
    raw_code = ["Given /^step with comments$/ do",
                "puts \"debug statement\"",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:lazy_debugging])
  end

  it "should punish each instance of lazy debugging (puts with literals)" do
    raw_code = ["Given /^step with comments$/ do",
                "puts %{debug statement}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:lazy_debugging])
  end

  it "should punish each instance of lazy debugging (p with single quotes)" do
    raw_code = ["Given /^step with comments$/ do",
                "p 'debug statement'",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:lazy_debugging])
  end

  it "should punish each instance of lazy debugging (p with double quotes)" do
    raw_code = ["Given /^step with comments$/ do",
                "p \"debug statement\"",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:lazy_debugging])
  end

  it "should punish each instance of lazy debugging (p with literal)" do
    raw_code = ["Given /^step with comments$/ do",
                "p %{debug statement}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:lazy_debugging])
  end

  it "should punish each instance of a pending step definition" do
    raw_code = ["Given /^step with comments$/ do",
                "pending",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:pending])
  end

  it "should punish each small sleep in a step definition" do
    raw_code = ["Given /^small sleeping step$/ do",
                "sleep #{RULES[:small_sleep][:max]}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:small_sleep])
  end

  it "should punish each large sleep in a step definition" do
    raw_code = ["Given /^small sleeping step$/ do",
                "sleep #{RULES[:large_sleep][:min] + 1}",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:large_sleep])
  end

  it "should punish each todo in a step definition" do
    raw_code = ["Given /^small sleeping step$/ do",
                "method_call(parameter) #todo figure out why this is being done",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, RULES[:todo])
  end
end
