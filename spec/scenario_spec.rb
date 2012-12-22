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
    scenario = [
        "Scenario Outline: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
        "Examples:",
        "|stuff|",
        "|a|"
    ]
    location = "path/path/path/my_feature.feature:1"
    step_definition = Scenario.new(location, scenario)
    step_definition.location.should == location
    step_definition.name.should == "Test Scenario"
    step_definition.steps.should == ["Given I am making a scenario",
                                     "When I make the scenario",
                                     "Then the scenario is made"]
    step_definition.examples_table.should == ["|stuff|",
                                              "|a|"]
  end

end