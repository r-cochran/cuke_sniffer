require 'spec_helper'

describe Scenario do

  it "should retain the passed location, name, and the steps of the scenario step after initialization" do
    scenario = [
        "Scenario: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    location = "path/path/path/my_feature.feature:1"
    step_definition = Scenario.new(location, scenario)
    step_definition.location.should == location
    step_definition.name.should == "Test Scenario"
    step_definition.steps.should == ["Given I am making a scenario",
                                     "When I make the scenario",
                                     "Then the scenario is made",]
  end

  it "should retain the information from scenario outlines" do
    scenario = [
        "Scenario Outline: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    location = "path/path/path/my_feature.feature:1"
    step_definition = Scenario.new(location, scenario)
    step_definition.location.should == location
    step_definition.name.should == "Test Scenario"
    step_definition.steps.should == ["Given I am making a scenario",
                                     "When I make the scenario",
                                     "Then the scenario is made"]
  end

  it "should retain the information from scenario templates" do
    scenario = [
        "Scenario Template: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    location = "path/path/path/my_feature.feature:1"
    step_definition = Scenario.new(location, scenario)
    step_definition.location.should == location
    step_definition.name.should == "Test Scenario"
    step_definition.steps.should == ["Given I am making a scenario",
                                     "When I make the scenario",
                                     "Then the scenario is made",]
  end

  it "should retain information on a tagged scenario" do
    scenario = [
        "@tag1 @tag2",
        "@tag3",
        "Scenario: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    location = "path/path/path/my_feature.feature:1"
    step_definition = Scenario.new(location, scenario)
    step_definition.location.should == location
    step_definition.name.should == "Test Scenario"
    step_definition.tags.should == ["@tag1", "@tag2", "@tag3"]
    step_definition.steps.should == ["Given I am making a scenario",
                                     "When I make the scenario",
                                     "Then the scenario is made",]
  end

  it "should retain the examples table if it is a scenario outline" do
    scenario_block = [
        "Scenario Outline: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
        "Examples:",
        "|stuff|",
        "|a|"
    ]
    location = "path/path/path/my_feature.feature:1"
    scenario = Scenario.new(location, scenario_block)
    scenario.location.should == location
    scenario.name.should == "Test Scenario"
    scenario.steps.should == ["Given I am making a scenario",
                              "When I make the scenario",
                              "Then the scenario is made"]
    scenario.examples_table.should == ["|stuff|",
                                       "|a|"]
  end

  it "should evaluate the scenario and the score should be greater than 0" do
    scenario_block = [
        "Scenario: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    scenario = Scenario.new("location", scenario_block)
    scenario.score = 0
    scenario.evaluate_score
    scenario.score.should > 0
  end

  it "should evaluate the scenario and then update a list of rules/occurrences" do
    scenario_block = [
        "Scenario: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    scenario = Scenario.new("location", scenario_block)
    scenario.rules_hash = {}
    scenario.evaluate_score
    scenario.rules_hash.should == {"Rule Descriptor" => 1}
  end

  it "should return the name for multi-line scenarios" do
    scenario = [
        "Scenario: Test",
        "My",
        "Multi-line",
        "Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    scenario = Scenario.new(nil, scenario)
    scenario.name.should == "Test My Multi-line Scenario"
  end
end