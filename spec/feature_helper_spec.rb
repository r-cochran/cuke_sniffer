require 'spec_helper'

describe FeatureHelper do

  it "should create a hash table of features from a folder where the key is the file name and the value is the feature object" do
    folder_path = "../features/scenarios"
    feature_hash = FeatureHelper.build_features_from_folder(folder_path)
    expected_hash = [
       Feature.new("../features/scenarios/complex_calculator.feature"),
       Feature.new("../features/scenarios/nested_directory/nested_feature.feature"),
       Feature.new("../features/scenarios/simple_calculator.feature"),
    ]
    feature_hash.should == expected_hash
  end

end
