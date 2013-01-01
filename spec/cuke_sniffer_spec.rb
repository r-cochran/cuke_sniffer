require 'spec_helper'

describe CukeSniffer do

  before(:each) do
    @features_location = "../features/scenarios"
    @step_definitions_location = "../features/step_definitions"
    @cuke_sniffer = CukeSniffer.new(@features_location, @step_definitions_location)
  end

  it "should use the passed locations for features and steps and store those create objects" do
    fail "features were not initialized" if @cuke_sniffer.features == {}
    fail "step definitions were not initialized" if @cuke_sniffer.step_definitions == []
  end

  it "should summarize the content of a cucumber suite including the min, max, and average scores of both Features and Step Definitions" do
    @cuke_sniffer.summary = {
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

    @cuke_sniffer.features[0].score = 3
    @cuke_sniffer.features[0].rules_hash = {"Rule Descriptor" => 3}
    @cuke_sniffer.step_definitions[0].score = 3
    @cuke_sniffer.step_definitions[0].rules_hash = {"Rule Descriptor" => 3}

    @cuke_sniffer.features = [@cuke_sniffer.features[0]]
    @cuke_sniffer.step_definitions = [@cuke_sniffer.step_definitions[0]]

    @cuke_sniffer.assess_score
    @cuke_sniffer.summary[:total_score].should > 0
    @cuke_sniffer.summary[:features][:min].should > 0
    @cuke_sniffer.summary[:features][:max].should > 0
    @cuke_sniffer.summary[:features][:average].should > 0
    @cuke_sniffer.summary[:step_definitions][:min].should > 0
    @cuke_sniffer.summary[:step_definitions][:max].should > 0
    @cuke_sniffer.summary[:step_definitions][:average].should > 0
    @cuke_sniffer.summary[:improvement_list].should_not == {}
  end

  it "should output results" do
    @cuke_sniffer.output_results.should =~ /Suite Summary\n\s*Total Score: \d*\n\s*Features \(.*\)\n\s*Min: \d*\n\s*Max: \d*\n\s*Average: \d*\n\s*Step Definitions \(.*\)\n\s*Min: \d*\n\s*Max: \d*\n\s*Average: \d*\n\s*Improvements to make:\n.*/
  end

  it "should catalog all calls a scenario and nested step definition calls" do

    scenario_block = [
        "Scenario: Empty Scenario",
        "Given live step",
        "When nested step"
    ]
    scenario = Scenario.new("ScenarioLocation:3", scenario_block)

    my_feature = Feature.new("#@features_location/simple_calculator.feature")
    my_feature.scenarios = [scenario]
    @cuke_sniffer.features = [my_feature]

    raw_code = ["When /^live step$/ do", "end"]
    live_step_definition = StepDefinition.new("LiveStep:1", raw_code)

    raw_code = ["When /^nested step$/ do",
                "steps \"When live step\"",
                "end"]
    nested_step_definition = StepDefinition.new("NestedStep:1", raw_code)

    my_step_definitions = [live_step_definition, nested_step_definition]

    @cuke_sniffer.step_definitions = my_step_definitions
    @cuke_sniffer.catalog_step_calls
    @cuke_sniffer.step_definitions[0].calls.count.should == 2
  end

  it "should not catalog a nested step called by a dead step" do

    scenario_block = [
        "Scenario: Empty Scenario",
    ]
    scenario = Scenario.new("ScenarioLocation:3", scenario_block)

    my_feature = Feature.new("#@features_location/simple_calculator.feature")
    my_feature.scenarios = [scenario]
    @cuke_sniffer.features = [my_feature]

    raw_code = ["When /^dead step$/ do", "end"]
    live_step_definition = StepDefinition.new("LiveStep:1", raw_code)

    raw_code = ["When /^nested step$/ do",
                "steps \"When dead step\"",
                "end"]
    nested_step_definition = StepDefinition.new("NestedStep:1", raw_code)

    my_step_definitions = [live_step_definition, nested_step_definition]

    @cuke_sniffer.step_definitions = my_step_definitions
    @cuke_sniffer.catalog_step_calls
    @cuke_sniffer.step_definitions[0].calls.count.should == 0
  end

  it "should identify dead step definitions" do
    @cuke_sniffer = CukeSniffer.new(@features_location, "../features/dead_step_definitions")
    dead_steps = @cuke_sniffer.get_dead_steps
    dead_steps.empty?.should be_false
  end

  it "should output rules" do
    cuke_sniffer = CukeSniffer.new("../features/rule_scenarios", "../features/rule_step_definitions")
    cuke_sniffer.output_results.should =~ /Suite Summary\n\s*Total Score: \d*\n\s*Features \(.*\)\n\s*Min: \d*\n\s*Max: \d*\n\s*Average: \d*\n\s*Step Definitions \(.*\)\n\s*Min: \d*\n\s*Max: \d*\n\s*Average: \d*\n\s*Improvements to make:\n.*/
  end

end
