require 'rspec'
require '../src/feature_helper'
require '../src/feature'
require '../src/scenario'

describe FeatureHelper do

  it "should create a hash table of features from a folder where the key is the file name and the value is the feature object" do
    folder_path = "../features/scenarios"
    feature_hash = FeatureHelper.build_features_from_folder(folder_path)
    expected_hash = {
        "../features/scenarios/dead_step_sorter_scenarios/complex_calculator.feature" => Feature.new("../features/scenarios/dead_step_sorter_scenarios/complex_calculator.feature"),
        "../features/scenarios/dead_step_sorter_scenarios/nested_directory/nested_feature.feature" => Feature.new("../features/scenarios/dead_step_sorter_scenarios/nested_directory/nested_feature.feature"),
        "../features/scenarios/dead_step_sorter_scenarios/simple_calculator.feature" => Feature.new("../features/scenarios/dead_step_sorter_scenarios/simple_calculator.feature"),
    }
    feature_hash.should == expected_hash
  end

end
