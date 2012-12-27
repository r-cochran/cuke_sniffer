require 'spec_helper'

describe Feature do

  before(:each) do
    @file_name = "my_feature.feature"
    file = File.open(@file_name, "w")
    file.puts("@tag1 @tag2")
    file.puts("@tag3")
    file.puts("\#@tag4")
    file.puts("Feature: My features are in this")
    file.puts("")
    file.puts("@simple_tag")
    file.puts("Scenario: My Test Scenario")
    file.puts("Given I want to be a test")
    file.puts("When I become a test")
    file.puts("Then I am a test")
    file.puts("")
    file.puts("@fun_tag")
    file.puts("Scenario: My Test Scenario 2")
    file.puts("Given I want to be a test")
    file.puts("When I become a test")
    file.puts("Then I am a test")
    file.close
    @feature = Feature.new(@file_name)
  end

  after(:each) do
    File.delete(@file_name)
  end

  it "should parse a feature file and gather the feature name" do
    @feature.location.should == @file_name
    @feature.name.should == "My features are in this"
  end

  it "should gather all non commented feature level tags" do
    @feature.tags.should == ["@tag1", "@tag2", "@tag3"]
  end

  it "should gather a scenario with its tags and create a scenario object and add feature level tags to the scenario" do
    scenario_1_text = [
        "@simple_tag",
        "Scenario: My Test Scenario",
        "Given I want to be a test",
        "When I become a test",
        "Then I am a test"
    ]
    expected_scenario_1 = Scenario.new("my_feature.feature:7", scenario_1_text)
    expected_scenario_1.tags += @feature.tags

    scenario_2_text = [
        "@fun_tag",
        "Scenario: My Test Scenario 2",
        "Given I want to be a test",
        "When I become a test",
        "Then I am a test"
    ]

    expected_scenario_2 = Scenario.new("my_feature.feature:5", scenario_2_text)
    expected_scenario_2.tags += @feature.tags

    @feature.scenarios.length.should == 2
    @feature.scenarios[0].should == expected_scenario_1
    @feature.scenarios[1].tags.should == expected_scenario_2.tags
  end

  it "should return all scenario tags in addition to feature tags" do
    file = File.open(@file_name, "w")
    file.puts("@tag1 @tag2")
    file.puts("@tag3")
    file.puts("\#@tag4")
    file.puts("Feature: My features are in this")
    file.puts("")
    file.puts("@simple_tag")
    file.puts("Scenario: My Test Scenario")
    file.puts("Given I want to be a test")
    file.puts("When I become a test")
    file.puts("Then I am a test")
    file.puts("")
    file.puts("@fun_tag")
    file.puts("@another_fun_tag")
    file.puts("Scenario: My Test Scenario 2")
    file.puts("Given I want to be a test")
    file.puts("When I become a test")
    file.puts("Then I am a test")
    file.puts("")
    file.puts("@another_multi_tag @multi_tag")
    file.puts("Scenario: My Test Scenario 2")
    file.puts("Given I want to be a test")
    file.puts("When I become a test")
    file.puts("Then I am a test")
    file.close
    @feature = Feature.new(@file_name)

    @feature.scenarios[0].tags.include?("@simple_tag").should be_true
    @feature.scenarios[1].tags.include?("@fun_tag").should be_true
    @feature.scenarios[1].tags.include?("@another_fun_tag").should be_true
    @feature.scenarios[2].tags.include?("@another_multi_tag").should be_true
    @feature.scenarios[2].tags.include?("@multi_tag").should be_true
  end

  it "should be able to parse Features files where there is no space between the 'Feature:' declaration and its description" do
    expected_feature_name = "My features are in this"
    file = File.open(@file_name, "w")
    file.puts("Feature:#{expected_feature_name}")
    file.puts("")
    file.puts("@simple_tag")
    file.puts("Scenario: My Test Scenario")
    file.puts("Given I want to be a test")
    file.puts("When I become a test")
    file.puts("Then I am a test")
    file.close
    @feature = Feature.new(@file_name)
    @feature.name.should == expected_feature_name
  end

  it "should to able to capture a feature description that spans multiple lines" do
    file = File.open(@file_name, "w")
    file.puts("Feature: I am a feature description")
    file.puts("that appears on multiple lines")
    file.puts("because it is legal in cucumber")
    file.puts("")
    file.puts("@simple_tag")
    file.puts("Scenario: My Test Scenario")
    file.puts("Given I want to be a test")
    file.puts("When I become a test")
    file.puts("Then I am a test")
    file.close
    @feature = Feature.new(@file_name)
    @feature.name.should == "I am a feature description that appears on multiple lines because it is legal in cucumber"
  end

  it "should be able to create a feature file without scenarios" do
    file = File.open(@file_name, "w")
    file.puts("Feature: I am a feature without scenarios")
    file.puts ""
    file.close
    @feature = Feature.new(@file_name)
    @feature.scenarios.should == []
  end

  it "should have a list of scenarios with rules evaluated" do
    scenario = @feature.scenarios[0]
    scenario.score.should >= 0
    scenario.rules_hash.should == {"Rule Descriptor" => 1}
  end

  it "should have a score and rules of the feature and the scenarios contained in it" do
    @feature.score = 0
    @feature.rules_hash = {}
    @feature.evaluate_score
    @feature.score.should == 3
    @feature.rules_hash.should == {"Rule Descriptor" => 3}
  end
end