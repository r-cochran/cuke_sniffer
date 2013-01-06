require 'spec_helper'

describe CukeSniffer do

  before(:each) do
    @features_location = "../features/scenarios"
    @step_definitions_location = "../features/step_definitions"
  end

  it "should use the passed locations for features and steps and store those create objects" do
    cuke_sniffer = CukeSniffer.new(@features_location, @step_definitions_location)
    fail "features were not initialized" if cuke_sniffer.features == {}
    fail "step definitions were not initialized" if cuke_sniffer.step_definitions == []
  end

  it "should summarize the content of a cucumber suite including the min, max, and average scores of both Features and Step Definitions" do
    cuke_sniffer = CukeSniffer.new(@features_location, @step_definitions_location)
    cuke_sniffer.summary = {
        :total_score => 0,
        :features => {
            :min => 0,
            :max => 0,
            :average => 0
        },
        :step_definitions => {
            :min => 0,
            :max => 0,
            :average => 0
        },
        :improvement_list => {}
    }

    cuke_sniffer.features[0].score = 3
    cuke_sniffer.features[0].rules_hash = {"Rule Descriptor" => 3}
    cuke_sniffer.step_definitions[0].score = 3
    cuke_sniffer.step_definitions[0].rules_hash = {"Rule Descriptor" => 3}

    cuke_sniffer.features = [cuke_sniffer.features[0]]
    cuke_sniffer.step_definitions = [cuke_sniffer.step_definitions[0]]

    cuke_sniffer.assess_score
    cuke_sniffer.summary[:total_score].should > 0
    cuke_sniffer.summary[:features][:min].should > 0
    cuke_sniffer.summary[:features][:max].should > 0
    cuke_sniffer.summary[:features][:average].should > 0
    cuke_sniffer.summary[:step_definitions][:min].should > 0
    cuke_sniffer.summary[:step_definitions][:max].should > 0
    cuke_sniffer.summary[:step_definitions][:average].should > 0
    cuke_sniffer.summary[:improvement_list].should_not == {}
  end

  it "should output results" do
    cuke_sniffer = CukeSniffer.new(@features_location, @step_definitions_location)
    puts cuke_sniffer.output_results
    cuke_sniffer.output_results.should =~ /Suite Summary\n\s*Total Score: [.0-9]*\n\s*Features \(.*\)\n\s*Min: [.0-9]*\n\s*Max: \d*\n\s*Average: [.0-9]*\n\s*Step Definitions \(.*\)\n\s*Min: [.0-9]*\n\s*Max: [.0-9]*\n\s*Average: [.0-9]*\n\s*Improvements to make:\n.*/
  end

  it "should catalog all calls a scenario and nested step definition calls" do
    cuke_sniffer = CukeSniffer.new(@features_location, @step_definitions_location)
    scenario_block = [
        "Scenario: Empty Scenario",
        "Given live step",
        "When nested step"
    ]
    scenario = Scenario.new("ScenarioLocation:3", scenario_block)

    my_feature = Feature.new("#@features_location/simple_calculator.feature")
    my_feature.scenarios = [scenario]
    cuke_sniffer.features = [my_feature]

    raw_code = ["When /^live step$/ do", "end"]
    live_step_definition = StepDefinition.new("LiveStep:1", raw_code)

    raw_code = ["When /^nested step$/ do",
                "steps \"When live step\"",
                "end"]
    nested_step_definition = StepDefinition.new("NestedStep:1", raw_code)

    my_step_definitions = [live_step_definition, nested_step_definition]

    cuke_sniffer.step_definitions = my_step_definitions
    cuke_sniffer.catalog_step_calls
    cuke_sniffer.step_definitions[0].calls.count.should == 2
  end

  it "should not catalog a nested step called by a dead step" do
    cuke_sniffer = CukeSniffer.new(@features_location, @step_definitions_location)
    scenario_block = [
        "Scenario: Empty Scenario",
    ]
    scenario = Scenario.new("ScenarioLocation:3", scenario_block)

    my_feature = Feature.new("#@features_location/simple_calculator.feature")
    my_feature.scenarios = [scenario]
    cuke_sniffer.features = [my_feature]

    raw_code = ["When /^dead step$/ do", "end"]
    live_step_definition = StepDefinition.new("LiveStep:1", raw_code)

    raw_code = ["When /^nested step$/ do",
                "steps \"When dead step\"",
                "end"]
    nested_step_definition = StepDefinition.new("NestedStep:1", raw_code)

    my_step_definitions = [live_step_definition, nested_step_definition]

    cuke_sniffer.step_definitions = my_step_definitions
    cuke_sniffer.catalog_step_calls
    cuke_sniffer.step_definitions[0].calls.count.should == 0
  end

  it "should identify dead step definitions" do
    lines = ["Given /^I am a dead step$/ do", "", "end"]
    file_name = "dead_steps.rb"
    file = File.open(file_name, "w")
    lines.each{|line| file.puts(line)}
    file.close

    cuke_sniffer = CukeSniffer.new(@features_location, Dir.getwd)
    dead_steps = cuke_sniffer.get_dead_steps
    dead_steps.empty?.should be_false
    File.delete(file_name)
  end

  it "should create a hash table of features from a folder where the key is the file name and the value is the feature object" do
    cuke_sniffer = CukeSniffer.new(@features_location, @step_definitions_location)
    folder_path = "../features/scenarios"
    feature_hash = cuke_sniffer.build_features_from_folder(folder_path)
    expected_hash = [
        Feature.new("../features/scenarios/complex_calculator.feature"),
        Feature.new("../features/scenarios/nested_directory/nested_feature.feature"),
        Feature.new("../features/scenarios/simple_calculator.feature"),
    ]
    feature_hash.should == expected_hash
  end

  it "should read every line of multiple step definition and segment those lines into steps." do
    cuke_sniffer = CukeSniffer.new(@features_location, @step_definitions_location)
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

    steps_array = cuke_sniffer.build_step_definitions(file_name)
    steps_array.count.should == 2

    File.delete(file_name)
  end

  it "should create a list of step definition objects from a step definition file." do
    cuke_sniffer = CukeSniffer.new(@features_location, @step_definitions_location)
    file_name = "my_steps.rb"
    file = File.open(file_name, "w")
    file.puts("Given /^I am a step$/ do")
    file.puts("  puts 'stuff'")
    file.puts("end")
    file.close

    expected_step_definitions = [
        StepDefinition.new("my_steps.rb:0", ["Given /^I am a step$/ do", "puts 'stuff'", "end"])
    ]
    step_definitions = cuke_sniffer.build_step_definitions(file_name)

    step_definitions.should == expected_step_definitions
    File.delete(file_name)
  end

  it "should create a list of step definition objects from a step definitions folder and its sub folders" do
    cuke_sniffer = CukeSniffer.new(@features_location, @step_definitions_location)
    folder_name = "../features/step_definitions"
    step_definitions = cuke_sniffer.build_step_definitions_from_folder(folder_name)

    expected_step_definitions = [
        StepDefinition.new("../features/step_definitions/complex_calculator_steps.rb:1", ["Given /^the first number is \"([^\"]*)\"$/ do |first_number|", "@first_number = first_number.to_i", "end"]),
        StepDefinition.new("../features/step_definitions/complex_calculator_steps.rb:5", ["When /^the second number is \"([^\"]*)\"$/ do |second_number|", "@second_number = second_number.to_i", "end"]),
        StepDefinition.new("../features/step_definitions/complex_calculator_steps.rb:9", ["Then /^the result is \"([^\"]*)\"$/ do |result|", "result.to_i.should == @first_number + @second_number", "end"]),
        StepDefinition.new("../features/step_definitions/nested_steps/nested_steps.rb:1", ["Given /^I am a nested step$/ do", "puts \"i have no functionality\"", "end"]),
        StepDefinition.new("../features/step_definitions/simple_calculator_steps.rb:1", ["Given /^the first number is 1$/ do", "steps \"Given the first number is \\\"1\\\"\"", "end"]),
        StepDefinition.new("../features/step_definitions/simple_calculator_steps.rb:5", ["When /^the second number is 1$/ do", "@second_number = 1", "end"]),
        StepDefinition.new("../features/step_definitions/simple_calculator_steps.rb:9", ["When /^the calculator adds$/ do", "@result = @first_number + @second_number", "end"]),
        StepDefinition.new("../features/step_definitions/simple_calculator_steps.rb:13", ["Then /^the result is 2$/ do", "@result.should == 2", "end"]),
    ]

    step_definitions.should == expected_step_definitions
  end

  it "should put the list of improvements in a descending order" do
    cuke_sniffer = CukeSniffer.new(@features_location, @step_definitions_location)
    cuke_sniffer.features = []
    step_definition = StepDefinition.new("location:1", ["Given // do", "end"])
    step_definition.rules_hash = {"Middle" => 2, "First" => 1, "Last" => 3}
    cuke_sniffer.step_definitions = [step_definition]
    cuke_sniffer.summary = {:total_score => 0, :features => {}, :step_definitions => {}, :improvement_list => {}}
    cuke_sniffer.assess_score

    puts cuke_sniffer.output_results
    cuke_sniffer.summary[:improvement_list].values.should == [3, 2, 1]
  end


end
