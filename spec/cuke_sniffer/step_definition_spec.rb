require 'spec_helper'
require 'cuke_sniffer/step_definition'

describe CukeSniffer::StepDefinition do
  after(:all) do
    delete_temp_files
  end

  it "should retain the passed location of the step after initialization" do
    step_definition_block = [
        "When /^the second number is 1$/ do",
        "@second_number = 1",
        "end"
    ]
    location = "path/path/path/my_steps.rb:1"
    step_definition = CukeSniffer::StepDefinition.new(location, step_definition_block)
    expect(step_definition.location).to eq location
  end

  it "should accept a simple step definition with no parameters it should divide that code into a regular expression, parameters, and code" do
    step_definition_block = [
        "When /^the second number is 1$/ do",
        "@second_number = 1",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.regex).to eq /^the second number is 1$/
    expect(step_definition.parameters).to be_empty
    expect(step_definition.code).to eq ["@second_number = 1"]
  end

  it "should accept a simple step definition with parameters it should divide that code into a regular expression, parameters, and code" do
    step_definition_block = [
        "Given /^the first number is \"([^\"]*)\"$/ do |first_number|",
        "@second_number = 1",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.regex).to eq /^the first number is "([^"]*)"$/
    expect(step_definition.parameters).to eq ["first_number"]
    expect(step_definition.code).to eq ["@second_number = 1"]
  end

  it 'is not impacted by excess whitespace around parameters' do
    step_definition_block = [
        "Given /a step/ do | param_1 ,  param_2,param_3    |",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.parameters).to eq [
        'param_1',
        'param_2',
        'param_3'
    ]
  end

  it "should add passed call locations (file + line) and their matched step call to a record hash" do
    step_definition_block = [
        "Given /^the first number is \"([^\"]*)\"$/ do |first_number|",
        "@second_number = 1",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    location = "myFile.rb:line 3"
    step_string = "the first number is \"1\""
    step_definition.add_call(location, step_string)
    expect(step_definition.calls).to include(location => step_string)
  end

  it "should evaluate 1 complex nested step with open and close on the same line" do
    nested_step = "the first number is \"1\""
    step_definition_block = [
        "Given /^the first number is 1$/ do |first_number|",
        "steps \"And #{nested_step}\"",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps).to include("location:2" => nested_step)
  end

  it "should evaluate 1 complex nested step with open on the same line" do
    nested_step = "the first number is \"1\""
    step_definition_block = [
        "Given /^the first number is 1$/ do |first_number|",
        "steps %Q{And #{nested_step}",
        "}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps).to include("location:2" => nested_step)
  end

  it "should capture a nested step with an expression" do
    nested_step = "this step has an \#{expression}"
    step_definition_block = [
        "Given /^This step has a passed in \"parameter\"$/ do |expression|",
        "steps %Q{And #{nested_step}}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps).to include("location:2" => nested_step)
  end

  it "should evaluate 1 complex nested step with the close on the same line" do
    nested_step = "the first number is \"1\""
    step_definition_block = [
        "Given /^the first number is 1$/ do |first_number|",
        "steps %Q{",
        "And #{nested_step}}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps).to include("location:3" => nested_step)
  end

  it "should evaluate 1 complex nested steps on its own line" do
    nested_step = "the first number is \"1\""
    step_definition_block = [
        "Given /^the first number is 1$/ do |first_number|",
        "steps %Q{",
        "And #{nested_step}",
        "}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps).to include("location:3" => nested_step)
  end

  it "should evaluate many complex nested step with steps on their own line" do
    nested_step = "the first number is \"1\""
    step_definition_block = [
        "Given /^the first number is 1$/ do |first_number|",
        "steps %Q{",
        "And #{nested_step}",
        "And #{nested_step}",
        "}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps).to include("location:3" => nested_step, "location:4" => nested_step)
  end

  it "should evaluate many complex nested step with steps on the start line, their own line, and the close line" do
    nested_step = "the first number is \"1\""
    step_definition_block = [
        "Given /^the first number is 1$/ do |first_number|",
        "steps %{And #{nested_step}",
        "And #{nested_step}",
        "And #{nested_step}",
        "And #{nested_step}}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps).to include(
        "location:2" => nested_step,
        "location:3" => nested_step,
        "location:4" => nested_step,
        "location:5" => nested_step
    )
  end

  it "should evaluate multiple sets of complex nested steps across multiple lines" do
    nested_step_set_one = "the first number is \"1\""
    nested_step_set_two = "the second number is \"55\""
    step_definition_block = [
        "Given /^the first number is 1$/ do |first_number|",
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
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps).to include(
        "location:3" => nested_step_set_one,
        "location:4" => nested_step_set_one,
        "location:8" => nested_step_set_two,
        "location:9" => nested_step_set_two,
        "location:10" => nested_step_set_two)
  end

  it "should determine if it is above the scenario threshold" do
    step_definition_block = [
        'Given /^$/ do/',
        'end'
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["StepDefinition"]
    CukeSniffer::Constants::THRESHOLDS["StepDefinition"] = 2
    step_definition.score = 3
    expect(step_definition.good?).to be false
    CukeSniffer::Constants::THRESHOLDS["StepDefinition"] = start_threshold
  end

  it "should determine if it is below the step definition threshold" do
    step_definition_block = [
        "Given /^step with no code$/ do",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["StepDefinition"]
    CukeSniffer::Constants::THRESHOLDS["StepDefinition"] = 200
    expect(step_definition.good?).to be true
    CukeSniffer::Constants::THRESHOLDS["StepDefinition"] = start_threshold
  end

  it "should determine the percentage of problems compared to the step definition threshold" do
    step_definition_block = [
        "Given /^step with no code$/ do",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["StepDefinition"]
    CukeSniffer::Constants::THRESHOLDS["StepDefinition"] = 2
    step_definition.score = 3
    expect(step_definition.problem_percentage).to be (3.0/2.0)
    CukeSniffer::Constants::THRESHOLDS["StepDefinition"] = start_threshold
  end

  it "should capture a nested step correctly that is defined in a string literal with spaces between the { and the start of the step" do
    step_definition_block = [
        "Given /^my step$/ do",
        "steps %{ And I am calling a nested step}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps.values.include?("I am calling a nested step")).to be true
  end

  it "should capture a nested step correctly that are on the same line as the closing of a string literal" do
    step_definition_block = [
        "Given /^my step$/ do",
        "steps %{",
        "And I am calling a nested step}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps.values.include?("I am calling a nested step")).to be true
  end

  it "should capture a nested step correctly that are on the same line as the opening of a string literal" do
    step_definition_block = [
        "Given /^my step$/ do",
        "steps %{And I am calling a nested step}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps.values.include?("I am calling a nested step")).to be true
  end

  it "should capture a nested step correctly that uses a } to close a variable use and is not the true end of the strings" do
    step_definition_block = [
        "Given /^my step$/ do",
        "steps %{And I am a nested step that uses a \#{variable}",
        "And this is the true end of the nested step}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps.values.include?("this is the true end of the nested step")).to be true
  end

  it "should capture nested steps when the 'step' call is used with simple string" do
    step_definition_block = [
        "Given /^step nested step call$/ do",
        "step \"And my nested step call\"",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps.values.include?("my nested step call")).to be true
  end

  it "should capture nested steps when the 'step' call is used with string literal" do
    step_definition_block = [
        "Given /^step nested step call$/ do",
        "step %{And my nested step call}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps.values.include?("my nested step call")).to be true
  end

  it "should capture nested steps used in conditional logic" do
    step_definition_block = [
        "Given /^step nested step call$/ do",
        "if steps %{And my nested step call}",
        "fail",
        "end",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps.values.include?("my nested step call")).to be true
  end

  it "should ignore commented lines when looking for nested steps" do
    step_definition_block = [
        "Given /^step nested step call$/ do",
        "#      steps %{And my nested step call}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps).to be_empty
  end

  it "should disregard nested steps that have \\ in their statements" do
    step_definition_block = [
        "Given /^step nested step call$/ do",
        "  steps %{And my nested step call says hello to \\\"John\\\"}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.nested_steps).to include("location:2" => 'my nested step call says hello to "John"')
    expect(step_definition.nested_steps.values[0]).to be =~ /my nested step call says hello to ".*"/
  end

  it "should return all recursive nested step definitions" do
    step_definition_block = [
        "Given /^recursive step$/ do",
        "  steps %{And recursive step}",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
    expect(step_definition.recursive_nested_steps).to include("location:2" => "recursive step")

  end

  describe "#todo" do
    it "returns all lines with todo and TODO found in the step definition" do
      step_definition_block = [
          "Given /^recursive step$/ do",
          "#TODO I need to do something here",
          "end"
      ]
      step_definition = CukeSniffer::StepDefinition.new("location:1", step_definition_block)
      expect(step_definition.todo).to eq ["#TODO I need to do something here"]
    end
  end
end

describe "StepDefinitionRules" do
  def run_rule_against_step_definition(step_definition_block, rule)
    @cli.step_definitions = [CukeSniffer::StepDefinition.new("location.rb:1",step_definition_block)]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
  end

  def test_step_definition_rule(step_definition_block, symbol, count = 1)
    rule = CukeSniffer::CukeSnifferHelper.build_rule(symbol, RULES[symbol])
    run_rule_against_step_definition(step_definition_block, rule)
    verify_rule(@cli.step_definitions.first, rule, count)
  end

  def test_no_step_definition_rule(step_definition_block, symbol)
    rule = CukeSniffer::CukeSnifferHelper.build_rule(symbol, RULES[symbol])
    run_rule_against_step_definition(step_definition_block, rule)
    verify_no_rule(@cli.step_definitions.first, rule)
  end

  before(:each) do
    @cli = CukeSniffer::CLI.new()
  end

  after(:all) do
    delete_temp_files
  end

  it "should punish Step Definitions with no code" do
    step_definition_block = [
        "Given /^step with no code$/ do",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :no_code)
  end

  it "should punish Step Definitions with too many parameters" do
    parameters = ""
    (RULES[:too_many_parameters][:max] + 1).times { |n| parameters += "param#{n}, " }
    step_definition_block = [
        "Given /^step with many parameters$/ do |#{parameters}|",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :too_many_parameters)
  end

  it "should punish Step Definitions that have nested steps" do
    step_definition_block = [
        "Given /^step with nested step call$/ do",
        "steps \"And I am a nested step\"",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :nested_step)
  end

  it "should punish Step Definitions that have recursive nested steps" do
    step_definition_block = [
        "Given /^step with recursive nested step call$/ do",
        "steps \"And step with recursive nested step call\"",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :recursive_nested_step)
  end

  it "should punish each commented line in a Step Definition" do
    step_definition_block = [
        "Given /^step with comments$/ do",
        "#steps \"And step with recursive nested step call\"",
        "#steps \"And step with recursive nested step call\"",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :commented_code, 2)
  end

  it "should punish each instance of lazy debugging (puts with single quotes)" do
    step_definition_block = [
        "Given /^step with comments$/ do",
        "puts 'debug statement'",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :lazy_debugging)
  end

  it "should punish each instance of lazy debugging (puts with double quotes)" do
    step_definition_block = [
        "Given /^step with comments$/ do",
        "puts \"debug statement\"",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :lazy_debugging)
  end

  it "should punish each instance of lazy debugging (puts with literals)" do
    step_definition_block = [
        "Given /^step with comments$/ do",
        "puts %{debug statement}",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :lazy_debugging)
  end

  it "should punish each instance of lazy debugging (p with single quotes)" do
    step_definition_block = [
        "Given /^step with comments$/ do",
        "p 'debug statement'",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :lazy_debugging)
  end

  it "should punish each instance of lazy debugging (p with double quotes)" do
    step_definition_block = [
        "Given /^step with comments$/ do",
        "p \"debug statement\"",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :lazy_debugging)
  end

  it "should punish each instance of lazy debugging (p with literal)" do
    step_definition_block = [
        "Given /^step with comments$/ do",
        "p %{debug statement}",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :lazy_debugging)
  end

  it "should punish each instance of a pending step definition" do
    step_definition_block = [
        "Given /^step with comments$/ do",
        "pending",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :pending)
  end

  it "should punish each instance of a pending with an attached message step definition" do
    step_definition_block = [
        "Given /^step with comments$/ do",
        "pending(\"happiness\")",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :pending)
  end

  it "should punish each instance of a pending with a trailing comment in step definition" do
    step_definition_block = [
        "Given /^step with comments$/ do",
        "pending # express the regexp above with the code you wish you had",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :pending)
  end

  it "should not punish anything named else that uses pending. Method Name." do
    step_definition_block = [
        "Given /^step with comments$/ do",
        "pendingMethodName",
        "end"
    ]
    test_no_step_definition_rule(step_definition_block, :pending)
  end

  it "should not punish anything named else that uses pending. Variable assignment." do
    step_definition_block = [
        "Given /^step with comments$/ do",
        "pending = 'testing'",
        "end"
    ]
    test_no_step_definition_rule(step_definition_block, :pending)
  end

  it "should punish each small sleep in a step definition" do
    step_definition_block = [
        "Given /^small sleeping step$/ do",
        "sleep #{RULES[:small_sleep][:max] - 1}",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :small_sleep)
  end

  it "should punish each large sleep in a step definition" do
    step_definition_block = [
        "Given /^small sleeping step$/ do",
        "sleep #{RULES[:large_sleep][:min] + 1}",
        "end"]
    test_step_definition_rule(step_definition_block, :large_sleep)
  end

  it "should punish each todo in a step definition" do
    step_definition_block = [
        "Given /^small sleeping step$/ do",
        "method_call(parameter) #todo figure out why this is being done",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :todo)
  end

  it "should punish universal nested step calls" do
    step_definition_block = [
        "Given /^step nested step call$/ do",
        "  steps %{And \#{variable_step_name}}",
        "end"
    ]
    test_step_definition_rule(step_definition_block, :universal_nested_step)
  end

end
