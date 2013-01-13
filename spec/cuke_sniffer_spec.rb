require 'spec_helper'

describe CukeSniffer do

  before(:each) do
    @features_location = File.dirname(__FILE__) + "/../features/scenarios"
    @step_definitions_location = File.dirname(__FILE__) + "/../features/step_definitions"
  end

  it "should be able to utilize a single feature file for parsing" do
    file_name = "single_feature.feature"
    file = File.open(file_name, "w")
    file.puts("Feature: I am the cheese that stands alone")
    file.close
    cuke_sniffer = CukeSniffer.new(file_name, nil)
    cuke_sniffer.features.should == [Feature.new(file_name)]
    File.delete(file_name)
  end

  it "should be able to utilize a single step definition file for parsing" do
    file_name = "single_steps.rb"
    file = File.open(file_name, "w")
    raw_code = ["Given /^I am a step$/ do", "end"]
    raw_code.each{|line| file.puts line}
    file.close
    cuke_sniffer = CukeSniffer.new(nil, file_name)
    cuke_sniffer.step_definitions.should == [StepDefinition.new("single.steps.rb:1", raw_code)]
    File.delete(file_name)
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

  it "should put the list of improvements in a descending order" do
    cuke_sniffer = CukeSniffer.new(@features_location, @step_definitions_location)
    cuke_sniffer.features = []
    step_definition = StepDefinition.new("location:1", ["Given // do", "end"])
    step_definition.rules_hash = {"Middle" => 2, "First" => 1, "Last" => 3}
    cuke_sniffer.step_definitions = [step_definition]
    cuke_sniffer.summary = {:total_score => 0, :features => {}, :step_definitions => {}, :improvement_list => {}}
    cuke_sniffer.assess_score

    cuke_sniffer.summary[:improvement_list].values.should == [3, 2, 1]
  end

end
