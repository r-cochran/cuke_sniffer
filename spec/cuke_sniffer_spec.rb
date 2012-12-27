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

  it "should condense all steps in a feature to a hash of location => step call" do
    steps = @cuke_sniffer.extract_steps_from_feature
    steps.keys.length.should == 9
  end

  it "should condense all nested steps in a step definition to a hash of location(augmented index) => step call" do
    steps = @cuke_sniffer.extract_steps_from_step_definitions
    steps.keys.length.should == 1
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
        :improvement_list => []
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
        :improvement_list => ["Rule Descriptor"]
    }
  end

  it "should output results" do
    @cuke_sniffer.output_results.should ==
"Suite Summary
  Total Score: 14
    Features (#{@features_location})
      Min: 2
      Max: 2
      Average: 2
    Step Definitions (#{@step_definitions_location})
      Min: 1
      Max: 1
      Average: 1
  Improvements to make:
    Rule Descriptor"
  end
end
