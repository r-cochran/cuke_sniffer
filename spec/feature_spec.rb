require 'spec_helper'

describe Feature do

  before(:each) do
    @file_name = "my_feature.feature"
    file = File.open(@file_name, "w")
    file.puts("Feature: I am a feature")
    file.puts ""
    file.close
  end

  after(:each) do
    File.delete(@file_name)
  end

  it "should parse a feature file and gather the feature name" do
    file = File.open(@file_name, "w")
    file.puts("Feature: My features are in this")
    file.close
    feature = Feature.new(@file_name)
    feature.location.should == @file_name
    feature.name.should == "My features are in this"
  end

  it "should to able to capture a feature description that spans multiple lines" do
    file = File.open(@file_name, "w")
    file.puts("Feature: I am a feature description")
    file.puts("that appears on multiple lines")
    file.puts("because it is legal in cucumber")
    file.puts("")
    file.close
    feature = Feature.new(@file_name)
    feature.name.should == "I am a feature description that appears on multiple lines because it is legal in cucumber"
  end

  it "should be able to parse Features files where there is no space between the 'Feature:' declaration and its description" do
    expected_feature_name = "My features are in this"
    file = File.open(@file_name, "w")
    file.puts("Feature:#{expected_feature_name}")
    file.close
    feature = Feature.new(@file_name)
    feature.name.should == expected_feature_name
  end

  it "should gather all non commented feature level tags" do
    file = File.open(@file_name, "w")
    file.puts("@tag1 @tag2")
    file.puts("@tag3")
    file.puts("\#@tag4")
    file.puts("Feature: My features are in this")
    file.close
    feature = Feature.new(@file_name)
    feature.tags.should == %w(@tag1 @tag2 @tag3)
  end

  it "should capture a background in a feature" do
    raw_code = [
        "Background: I am a background",
        "Given I want to be a test",
        "When I become a test",
        "Then I am a test"
    ]
    file = File.open(@file_name, "w")
    file.puts("Feature: Feature with background")
    file.puts("")
    raw_code.each { |line| file.puts(line) }
    file.close

    scenario = Scenario.new("#@file_name:3", raw_code)
    feature = Feature.new(@file_name)
    feature.background == scenario
    feature.scenarios.empty?.should == true
  end

  it "should gather a scenario with its tags and create a scenario object and add feature level tags to the scenario" do
    file = File.open(@file_name, "w")
    file.puts("@feature_tag")
    file.puts("Feature: My features are in this")
    file.puts("")
    file.puts("@scenario_tag")
    file.puts("Scenario: My Test Scenario")
    file.close

    feature = Feature.new(@file_name)

    feature.scenarios[0].tags.should == %w(@scenario_tag @feature_tag)
  end

  it "should be able to create a feature file without scenarios" do
    file = File.open(@file_name, "w")
    file.puts("Feature: I am a feature without scenarios")
    file.puts ""
    file.close
    feature = Feature.new(@file_name)
    feature.scenarios.should == []
  end

  it "should include the scores of a background in a feature" do
    file = File.open(@file_name, "w")
    file.puts("Feature: Feature with background")
    file.puts("")
    file.puts("Background: I am a background")
    file.puts("And I want to be a test")
    file.close

    feature = Feature.new(@file_name)
    feature.rules_hash.include?("First step began with And/But").should be_true
    feature.rules_hash["First step began with And/But"].should == 1
  end

  it "should have a score and rules hash made up of the feature and its scenarios" do
    feature = Feature.new(@file_name)
    feature.score = 0
    feature.rules_hash = {}

    my_scenario = Scenario.new("location:1", ["Scenario: Trigger a rule"])
    my_scenario.score = 1
    my_scenario.rules_hash = {"Rule Descriptor" => 1}
    feature.scenarios[0] = my_scenario

    feature.evaluate_score
    feature.score.should == 1
    feature.rules_hash.should == {"Rule Descriptor" => 1}
  end

end

describe "FeatureRules" do

  before(:each) do
    @file_name = "my_feature.feature"
  end

  after(:each) do
    File.delete(@file_name)
  end

  it "should punish Features with too many tags" do
    file = File.open(@file_name, "w")
    8.times { |n| file.puts "@tag_#{n}" }
    file.puts("Feature: Feature with many tags")
    file.close

    feature = Feature.new(@file_name)
    feature.rules_hash.include?("Feature has too many tags").should be_true
    feature.rules_hash["Feature has too many tags"].should == 1
  end

  it "should punish Features without a name" do
    file = File.open(@file_name, "w")
    file.puts("Feature:")
    file.puts("")
    file.puts("Scenario: My Test Scenario")
    file.puts("Given I want to be a test")
    file.puts("When I become a test")
    file.puts("Then I am a test")
    file.close
    feature = Feature.new(@file_name)
    feature.rules_hash.include?("No Feature Description!").should be_true
    feature.rules_hash["No Feature Description!"].should > 0
  end

  it "should punish Features with numbers in its name" do
    file = File.open(@file_name, "w")
    file.puts("Feature: Story Card 12345")
    file.close
    feature = Feature.new(@file_name)
    feature.rules_hash.include?("Feature has number(s) in the title").should be_true
    feature.rules_hash["Feature has number(s) in the title"].should > 0
  end

  it "should punish Features with long names" do
    feature_description = ""
    180.times { feature_description << "A" }
    file = File.open(@file_name, "w")
    file.puts("Feature: #{feature_description}")
    file.close
    feature = Feature.new(@file_name)
    feature.rules_hash.include?("Feature title is too long").should be_true
    feature.rules_hash["Feature title is too long"].should > 0
  end

  it "should punish Features that have a background but no Scenarios" do
    file = File.open(@file_name, "w")
    file.puts("Feature: Feature with background and no scenarios")
    file.puts("")
    file.puts("Background: I am a background")
    file.puts("And I want to be a test")
    file.close

    feature = Feature.new(@file_name)
    feature.rules_hash.include?("Feature has background with no scenarios").should be_true
    feature.rules_hash["Feature has background with no scenarios"].should == 1
  end

  it "should punish Features that have a background and only one Scenario" do
    file = File.open(@file_name, "w")
    file.puts("Feature: Feature with background and one scenario")
    file.puts("")
    file.puts("Background: I am a background")
    file.puts("And I want to be a test")
    file.puts("")
    file.puts("Scenario: One scenario")
    file.close

    feature = Feature.new(@file_name)
    feature.rules_hash.include?("Feature has background with one scenarios").should be_true
    feature.rules_hash["Feature has background with one scenarios"].should == 1
  end

  it "should punish Features with zero Scenarios" do
    file = File.open(@file_name, "w")
    file.puts("Feature: I'm a feature without scenarios!")
    file.close
    feature = Feature.new(@file_name)
    feature.rules_hash.include?("Feature with no scenarios").should be_true
    feature.rules_hash["Feature with no scenarios"].should > 0
  end

  it "should punish Features with too many Scenarios" do
    file = File.open(@file_name, "w")
    file.puts("Feature: I'm a feature without scenarios!")
    10.times { file.puts "Scenario: I am a simple scenario" }
    file.close
    feature = Feature.new(@file_name)
    feature.rules_hash.include?("Feature with too many scenarios").should be_true
    feature.rules_hash["Feature with too many scenarios"].should > 0
  end

end