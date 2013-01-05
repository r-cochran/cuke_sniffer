require 'spec_helper'

describe StepDefinition do

  it "should retain the passed location of the step after initialization" do
    raw_code = ["When /^the second number is 1$/ do",
                "@second_number = 1",
                "end"]
    location = "path/path/path/my_steps.rb:1"
    step_definition = StepDefinition.new(location, raw_code)
    step_definition.location.should == location
  end

  it "should accept a simple step definition with no parameters it should divide that code into a regular expression, parameters, and code" do
    raw_code = ["When /^the second number is 1$/ do",
                "@second_number = 1",
                "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
    step_definition.regex.should == /^the second number is 1$/
    step_definition.parameters.should == []
    step_definition.code.should == ["@second_number = 1"]
  end

  it "should accept a simple step definition with parameters it should divide that code into a regular expression, parameters, and code" do
    raw_code = ["Given /^the first number is \"([^\"]*)\"$/ do |first_number|",
                "@second_number = 1",
                "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
    step_definition.regex.should == /^the first number is "([^"]*)"$/
    step_definition.parameters.should == %w"first_number"
    step_definition.code.should == ["@second_number = 1"]
  end

  it "should add passed call locations (file + line) and their matched step call to a record hash" do
    raw_code = ["Given /^the first number is \"([^\"]*)\"$/ do |first_number|",
                "@second_number = 1",
                "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
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
    step_definition = StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {"location:2" => nested_step}
  end

  it "should evaluate 1 complex nested step with open on the same line" do
    nested_step = "the first number is \"1\""
    raw_code = ["Given /^the first number is 1$/ do |first_number|",
                "steps %{And #{nested_step}",
                "}",
                "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {"location:2" => nested_step}
  end

  it "should evaluate 1 complex nested step with the close on the same line" do
    nested_step = "the first number is \"1\""
    raw_code = ["Given /^the first number is 1$/ do |first_number|",
                "steps %{",
                "And #{nested_step}}",
                "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {"location:3" => nested_step}
  end

  it "should evaluate 1 complex nested steps on its own line" do
    nested_step = "the first number is \"1\""
    raw_code = ["Given /^the first number is 1$/ do |first_number|",
                "steps %{",
                "And #{nested_step}",
                "}",
                "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
    step_definition.nested_steps.should == {"location:3" => nested_step}
  end

  it "should evaluate many complex nested step with steps on their own line" do
    nested_step = "the first number is \"1\""
    raw_code = ["Given /^the first number is 1$/ do |first_number|",
                "steps %{",
                "And #{nested_step}",
                "And #{nested_step}",
                "}",
                "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
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
    step_definition = StepDefinition.new("location:1", raw_code)
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
    step_definition = StepDefinition.new("location:1", raw_code)
    step_definition.score = 0
    step_definition.evaluate_score
    step_definition.score.should > 0
  end

  it "should evaluate the step definition and then update a list of rules/occurrences" do
    raw_code = ["Given /^step with no code$/ do",
                "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
    step_definition.rules_hash = {}
    step_definition.evaluate_score
    step_definition.rules_hash.should_not == {}
  end

  it "should have a score and rule list immediately after being created" do
    raw_code = ["Given /^step with no code$/ do",
                "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
    step_definition.score.should > 0
    step_definition.rules_hash.should_not == {}
  end

end

describe "StepDefinitionRules" do

  def validate_rule(step_definition, rule)
    phrase = rule[:phrase].gsub(/{.*}/, "Scenario")

    step_definition.rules_hash.include?(phrase).should be_true
    step_definition.rules_hash[phrase].should > 0
    step_definition.score.should >= rule[:score]
  end

  it "should punish Step Definitions with no code" do
    raw_code = ["Given /^step with no code$/ do",
                "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
   validate_rule(step_definition, STEP_DEFINITION_RULES[:no_code])
  end

  it "should punish Step Definitions with too many parameters" do
    rule = STEP_DEFINITION_RULES[:too_many_parameters]
    parameters = ""
    rule[:max].times{|n| parameters += "param#{n}, "}

    raw_code = ["Given /^step with many parameters$/ do |#{parameters}|", "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, rule)
  end

  it "should punish Step Definitions that have nested steps" do
    raw_code = ["Given /^step with nested step call$/ do", "steps \"And I am a nested step\"", "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, STEP_DEFINITION_RULES[:nested_step])
  end

  it "should punish Step Definitions that have recursive nested steps" do
    raw_code = ["Given /^step with recursive nested step call$/ do", "steps \"And step with recursive nested step call\"", "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, STEP_DEFINITION_RULES[:recursive_nested_step])
  end

  it "should punish each commented line in a Step Definition" do
    raw_code = ["Given /^step with comments$/ do",
                "#steps \"And step with recursive nested step call\"",
                "#steps \"And step with recursive nested step call\"",
                "end"]
    step_definition = StepDefinition.new("location:1", raw_code)
    validate_rule(step_definition, STEP_DEFINITION_RULES[:commented_code])
  end
end