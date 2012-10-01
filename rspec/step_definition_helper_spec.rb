require 'rspec'
require '../src/step_definition_helper'
require '../src/step_definition'

describe StepDefinitionHelper do

  before(:each) do
    @step_definition_helper = StepDefinitionHelper.new
  end
  
  it "should read every line of a single step definition and segment those lines into steps identified by its location." do
    file_name = "my_steps.rb"
    file = File.open(file_name, "w")
    file.puts("Given /^I am a step$/ do")
    file.puts("  puts 'stuff'")
    file.puts("end")
    file.close

    expected_steps_array = {
        "my_steps.rb:1" =>
            [
                "Given /^I am a step$/ do",
                "puts 'stuff'",
                "end"
            ]
    }

    steps_array = StepDefinitionHelper.parse_step_definitions(file_name)
    steps_array.should == expected_steps_array

    File.delete(file_name)
  end

  it "should ignore commented open and close segments for identifying step code" do
    file_name = "my_steps.rb"
    file = File.open(file_name, "w")
    file.puts("Given /^I am a step$/ do")
    file.puts ("#if true {")
    file.puts ("puts 'no'")
    file.puts ("#}")
    file.puts ("#}")
    file.puts("  puts 'stuff'")
    file.puts("end")
    file.close

    expected_steps_array = {
        "my_steps.rb:1" =>
            [
                "Given /^I am a step$/ do",
                "#if true {",
                "puts 'no'",
                "#}",
                "#}",
                "puts 'stuff'",
                "end"
            ]
    }

    steps_array = StepDefinitionHelper.parse_step_definitions(file_name)
    steps_array.should == expected_steps_array

    File.delete(file_name)
  end

  it "should read every line of multiple step definition and segment those lines into steps." do
    file_name = "my_steps.rb"
    file = File.open(file_name, "w")
    file.puts("Given /^I am a step$/ do")
    file.puts("  puts 'stuff'")
    file.puts("end")
    file.puts("")
    file.puts("And /^I too am a step$/ do")

    file.puts("if true {")
    file.puts("puts 'no'")
    file.puts("}")
    file.puts("end")
    file.close

    expected_steps_array = {
        "my_steps.rb:1" =>
            [
                "Given /^I am a step$/ do",
                "puts 'stuff'",
                "end"
            ],
        "my_steps.rb:5" =>
            [
                "And /^I too am a step$/ do",
                "if true {",
                "puts 'no'",
                "}",
                "end"
            ]
    }

    steps_array = StepDefinitionHelper.parse_step_definitions(file_name)
    steps_array.should == expected_steps_array

    File.delete(file_name)
  end

  it "should create a list of step definition objects from a step definition file." do
    file_name = "my_steps.rb"
    file = File.open(file_name, "w")
    file.puts("Given /^I am a step$/ do")
    file.puts("  puts 'stuff'")
    file.puts("end")
    file.close

    expected_step_definitions = [
        StepDefinition.new("my_steps.rb:0", ["Given /^I am a step$/ do", "puts 'stuff'", "end"])
    ]
    step_definitions = StepDefinitionHelper.build_step_definitions(file_name)

    step_definitions.should == expected_step_definitions
    File.delete(file_name)
  end

  it "should create a list of step definition objects from a step definitions folder and its sub folders" do
    folder_name = "../features/step_definitions"
    step_definitions = StepDefinitionHelper.build_step_definitions_from_folder(folder_name)

    expected_step_definitions = [
        StepDefinition.new("../features/step_definitions/dead_step_sorter_steps/complex_calculator_steps.rb:0", ["Given /^the first number is \"([^\"]*)\"$/ do |first_number|", "@first_number = first_number.to_i", "end"]),
        StepDefinition.new("../features/step_definitions/dead_step_sorter_steps/complex_calculator_steps.rb:4", ["When /^the second number is \"([^\"]*)\"$/ do |second_number|","@second_number = second_number.to_i", "end"]),
        StepDefinition.new("../features/step_definitions/dead_step_sorter_steps/complex_calculator_steps.rb:8", ["Then /^the result is \"([^\"]*)\"$/ do |result|","result.to_i.should == @first_number + @second_number", "end"]),
        StepDefinition.new("../features/step_definitions/dead_step_sorter_steps/nested_steps/nested_steps.rb:0", ["Given /^I am a nested step$/ do", "puts \"i have no functionality\"", "end"]),
        StepDefinition.new("../features/step_definitions/dead_step_sorter_steps/simple_calculator_steps.rb:0", ["Given /^the first number is 1$/ do", "steps \"Given the first number is \\\"1\\\"\"", "end"]),
        StepDefinition.new("../features/step_definitions/dead_step_sorter_steps/simple_calculator_steps.rb:4", ["When /^the second number is 1$/ do", "@second_number = 1", "end"]),
        StepDefinition.new("../features/step_definitions/dead_step_sorter_steps/simple_calculator_steps.rb:8", ["When /^the calculator adds$/ do","@result = @first_number + @second_number", "end"]),
        StepDefinition.new("../features/step_definitions/dead_step_sorter_steps/simple_calculator_steps.rb:12", ["Then /^the result is 2$/ do","@result.should == 2", "end"]),
      ]

    step_definitions.should == expected_step_definitions
  end
end