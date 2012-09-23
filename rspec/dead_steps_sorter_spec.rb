require 'rspec'
require '../source/dead_steps_sorter'

describe DeadStepsSorter do

  before(:each) do
    @dead_steps_sorter = DeadStepsSorter.new
  end

  it "should get all steps in a feature file with simple steps." do
    file_name = "../features/scenarios/dead_step_sorter_scenarios/simple_calculator.feature"
    list_of_steps = @dead_steps_sorter.get_list_of_steps_from_feature_file(file_name)
    list_of_steps.should == ["the first number is 1", "the second number is 1", "the calculator adds", "the result is 2"]
  end

  it "should get all steps in a feature folder, including nested folders" do
    folder_name = "../features/scenarios/dead_step_sorter_scenarios/"
    list_of_steps = @dead_steps_sorter.get_list_of_steps_from_features_folder(folder_name)
    expected_list = ["the first number is 1", "the second number is 1", "the result is 2", "the first number is \"1\"", "the second number is \"1\"", "the calculator adds", "the result is \"2\"", "I am a nested step"]
    list_of_steps.length.should == expected_list.length
    list_of_steps.each { |step|
      expected_list.include?(step).should == true
    }
  end

  it "should get all steps in a feature file with complex steps." do
    file_name = "../features/scenarios/dead_step_sorter_scenarios/complex_calculator.feature"
    list_of_steps = @dead_steps_sorter.get_list_of_steps_from_feature_file(file_name)
    list_of_steps.should == ["the first number is \"1\"", "the second number is \"1\"", "the calculator adds", "the result is \"2\""]
  end

  it "should get all steps in a step_definitions folder" do
    folder_name = "../features/step_definitions/dead_step_sorter_steps/"
    list_of_steps = @dead_steps_sorter.get_list_of_steps_from_step_definition_folder(folder_name)
    expected_list = ["the first number is 1", "the second number is 1", "the calculator adds", "the result is 2", "the first number is \"([^\"]*)\"", "the second number is \"([^\"]*)\"", "the result is \"([^\"]*)\"", "I am a nested step"]
    list_of_steps.length.should == expected_list.length
    list_of_steps.each { |step|
      expected_list.include?(step).should == true
    }
  end

  it "should get all the steps in a step file with simple steps." do
    file_name = "../features/step_definitions/dead_step_sorter_steps/simple_calculator_steps.rb"
    list_of_steps = @dead_steps_sorter.get_list_of_steps_from_step_file(file_name)
    list_of_steps.should == ["the first number is 1", "the second number is 1", "the calculator adds", "the result is 2"]
  end

  it "should get all the steps in a step file with complex steps." do
    file_name = "../features/step_definitions/dead_step_sorter_steps/complex_calculator_steps.rb"
    list_of_steps = @dead_steps_sorter.get_list_of_steps_from_step_file(file_name)
    list_of_steps.should == ["the first number is \"([^\"]*)\"", "the second number is \"([^\"]*)\"", "the result is \"([^\"]*)\""]
  end

  it "should determine a list of dead steps when comparing simple feature steps to simple step steps" do
    feature_list_of_steps = ["the first number is 1", "the second number is 2"]
    step_list_of_steps = ["the first number is 1", "the second number is 2", "the calculator adds"]
    list_of_dead_steps = @dead_steps_sorter.get_list_of_dead_steps(feature_list_of_steps, step_list_of_steps)
    list_of_dead_steps.should == ["the calculator adds"]
  end

  it "should return true if a step regex exists in a simple list" do
    regex = /the first number is 1/
    step_list = ["the first number is 1"]
    result = @dead_steps_sorter.regex_in_step_list?(regex, step_list)
    result.should == true
  end

  it "should return false if a step regex does not exist in a simple list" do
    regex = /the first number is 1/
    step_list = ["the first number is 2"]
    result = @dead_steps_sorter.regex_in_step_list?(regex, step_list)
    result.should == false
  end

  it "should determine a list of dead steps when comparing complex feature steps to complex step steps" do
    feature_list_of_steps = ["the first number is \"1\"", "the second number is \"2\""]
    step_list_of_steps = ["the first number is \"([^\"]*)\"", "the second number is \"([^\"]*)\"", "the calculator adds"]
    list_of_dead_steps = @dead_steps_sorter.get_list_of_dead_steps(feature_list_of_steps, step_list_of_steps)
    list_of_dead_steps.should == ["the calculator adds"]
  end

  it "should return true if a step regex exists in a complex list" do
    regex = /the first number is \"([^\"]*)\"/
    step_list = ["the first number is \"1\""]
    result = @dead_steps_sorter.regex_in_step_list?(regex, step_list)
    result.should == true
  end

  it "should return false if a step regex does not exist in a complex list" do
    regex = /the first number is \"([^\"]*)\"/
    step_list = ["the first number is bacon"]
    result = @dead_steps_sorter.regex_in_step_list?(regex, step_list)
    result.should == false
  end

  it "should capture a whole simple steps" do
    step = "the calculator adds"
    file_name = "../features/step_definitions/dead_step_sorter_steps/simple_calculator_steps.rb"
    step_code = @dead_steps_sorter.get_step_code(step, file_name)
    step_code.should == "When /^the calculator adds$/ do\n  @result = @first_number + @second_number\nend\n"
  end

  it "should move dead steps to dead_steps.rb" do
    dead_step = "I am a dead step"
    file_name = "temp_dead_steps.rb"
    file = File.open(file_name, "w")
    file.puts("Given /^#{dead_step}$/ do")
    file.puts("  puts 'stuff'")
    file.puts("end")
    file.close

    list_of_dead_steps = [dead_step, "Banana"]
    step_definitions_folder = "#{Dir.getwd}/"
    @dead_steps_sorter.move_dead_steps(step_definitions_folder, list_of_dead_steps)

    temp_file = File.open("dead_steps.rb", "r")
    content_of_dead_steps_file = temp_file.read
    temp_file.close

    File.delete(file_name)
    File.delete("dead_steps.rb")

    content_of_dead_steps_file.should == "##{Dir.getwd}/temp_dead_steps.rb\nGiven /^I am a dead step$/ do\n  puts 'stuff'\nend\n"
  end

end