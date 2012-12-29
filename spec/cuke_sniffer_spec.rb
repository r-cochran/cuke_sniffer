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
    @cuke_sniffer.assess_score
    @cuke_sniffer.summary.should == {
        :total_score => 14,
        :features => {
            :min => 2,
            :max => 2,
            :average => 2
        },
        :step_definitions => {
            :min => 1,
            :max => 1,
            :average => 1
        },
        :improvement_list => {"Rule Descriptor" => 14}
    }
  end

  it "should output results" do
    @cuke_sniffer.output_results.should ==
"Suite Summary
  Total Score: 14
    Features (#@features_location)
      Min: 2
      Max: 2
      Average: 2
    Step Definitions (#@step_definitions_location)
      Min: 1
      Max: 1
      Average: 1
  Improvements to make:
    (14)Rule Descriptor"
  end

  it "should catalog all calls a step definition has" do
    @cuke_sniffer.step_definitions[0].calls.empty?.should be_true
    @cuke_sniffer.catalog_step_calls
    @cuke_sniffer.step_definitions[0].calls.empty?.should be_false
  end

  it "should identify dead step definitions" do
    @cuke_sniffer = CukeSniffer.new(@features_location, "../features/dead_step_definitions")
    dead_steps = @cuke_sniffer.get_dead_steps
    dead_steps.empty?.should be_false
  end

  it "should output rules" do
    cuke_sniffer = CukeSniffer.new("../features/rule_scenarios", "../features/rule_step_definitions")
    cuke_sniffer.output_results.should ==
"Suite Summary
  Total Score: 15
    Features (../features/rule_scenarios)
      Min: 15
      Max: 15
      Average: 15
    Step Definitions (../features/rule_step_definitions)
      Min:\s
      Max:\s
      Average:\s
  Improvements to make:
    (3)Rule Descriptor
    (2)Scenario with no steps!
    (1)No Scenario Description!
    (1)No Feature Description!"
  end

end
