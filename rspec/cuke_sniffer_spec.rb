require 'rspec'
require '../src/step_definition_helper'
require '../src/step_definition'

require '../src/feature_helper'
require '../src/feature'
require '../src/scenario'

require '../src/cuke_sniffer'

describe CukeSniffer do

  before(:each) do
    features_location = "../features/scenarios"
    step_definitions_location = "../features/step_definitions"
    @cuke_sniffer = CukeSniffer.new(features_location, step_definitions_location)
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
end
