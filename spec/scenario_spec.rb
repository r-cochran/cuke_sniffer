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
    step_definition.tags.should == %w(@tag1 @tag2 @tag3)
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
    scenario.examples_table.should == %w(|stuff| |a|)
  end

  it "should retain the type of scenario" do
    scenario_block = [
        "Scenario: Test Scenario",
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.type.should == "Scenario"
  end

  it "should retain the type of scenario outline" do
    scenario_block = [
        "Scenario Outline: Test Scenario",
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.type.should == "Scenario Outline"
  end

  it "should evaluate the scenario and the score should be greater than 0" do
    scenario_block = [
        "Scenario: Test Scenario with empty scenario rule firing",
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.score = 0
    scenario.evaluate_score
    scenario.score.should > 0
  end

  it "should evaluate the scenario and then update a list of rules/occurrences" do
    scenario_block = [
        "Scenario: Test Scenario to fire empty scenario rule",
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash = {}
    scenario.evaluate_score
    scenario.rules_hash.should_not == {}
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
    scenario = Scenario.new("location:1", scenario)
    scenario.name.should == "Test My Multi-line Scenario"
  end

  it "should have a rule for empty scenario names" do
    scenario_block = [
        "Scenario:",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("No Scenario Description!").should be_true
    scenario.rules_hash["No Scenario Description!"].should > 0
  end

  it "should have a rule for a scenario with no steps" do
    scenario_block = [
        "Scenario: Empty Scenario",
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Scenario with no steps!").should be_true
    scenario.rules_hash["Scenario with no steps!"].should > 0
  end

  it "should have a rule and associated score for a scenario name containing digits" do
    scenario_block = [
        "Scenario: Scenario with some digits 123"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Scenario has number(s) in the title").should be_true
    scenario.rules_hash["Scenario has number(s) in the title"].should > 0
  end

  it "should have a rule and associated score for a scenario name with a very long description" do
    scenario_description = ""
    180.times{scenario_description << "A"}
    scenario_block = [
        "Scenario: #{scenario_description}"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Scenario title is too long").should be_true
    scenario.rules_hash["Scenario title is too long"].should > 0
  end

  it "should have a rule and associated score for a scenario with too many steps" do
    scenario_block = [
        "Scenario: Scenario with too many steps"
    ]

    7.times {scenario_block << "And I have too many steps"}

    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Scenario has too many steps").should be_true
    scenario.rules_hash["Scenario has too many steps"].should > 0
  end

  it "should have a rule and associated score for a scenario with Then/When steps" do
    scenario_block = [
        "Scenario: Scenario with out of order steps",
        "Then comes first",
        "When comes second"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Steps are out of Given/When/Then order").should be_true
    scenario.rules_hash["Steps are out of Given/When/Then order"].should > 0
  end

  it "should have a rule and associated score for a scenario with Then/When/Given steps" do
    scenario_block = [
        "Scenario: Scenario with out of order steps",
        "Then comes first",
        "When comes second",
        "Given comes third"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Steps are out of Given/When/Then order").should be_true
    scenario.rules_hash["Steps are out of Given/When/Then order"].should > 0
  end

  it "should have a rule and associated score for a scenario with Given/Then/And/When steps" do
    scenario_block = [
        "Scenario: Scenario with out of order steps",
        "Given comes first",
        "Then comes second",
        "And is ignored",
        "When comes third"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Steps are out of Given/When/Then order").should be_true
    scenario.rules_hash["Steps are out of Given/When/Then order"].should > 0
  end

  it "should have a rule and associate score for a scenario with And as the first step" do
    scenario_block = [
        "Scenario: Scenario with And as its first step",
        "And is not a valid first step",
        "When comes first"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("First step began with And/But").should be_true
    scenario.rules_hash["First step began with And/But"].should > 0
  end

  it "should have a rule and associate score for a scenario with But as the first step" do
    scenario_block = [
        "Scenario: Scenario with But as its first step",
        "But is not a valid first step",
        "When comes first"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("First step began with And/But").should be_true
    scenario.rules_hash["First step began with And/But"].should > 0
  end

  it "should have a rule and associate score for a scenario with And as the only steps" do
    scenario_block = [
        "Scenario: Scenario with multiple And steps",
        "And is not a valid first step",
        "And comes first"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("First step began with And/But").should be_true
    scenario.rules_hash.include?("Steps are out of Given/When/Then order").should be_true
    scenario.rules_hash["First step began with And/But"].should == 1
    scenario.rules_hash["Steps are out of Given/When/Then order"].should == 1
  end

  it "should have a rule and associate score for a scenario with * as a step" do
    scenario_block = [
        "Scenario: Scenario with *",
        "* is an awesome operator"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Steps includes a *").should be_true
    scenario.rules_hash["Steps includes a *"].should == 1
  end

  it "should have record a rule occurrence and increment the score for each step in a scenario with an *" do
    scenario_block = [
        "Scenario: Scenario with *",
        "Given I am first",
        "* is an awesome operator",
        "When I am second",
        "* is an awesome operator",
        "Then I am third"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.score.should >= 4
    scenario.rules_hash["Steps includes a *"].should == 2
  end

  it "should have record a rule occurrence and increment the score for a commented step in a scenario" do
    scenario_block = [
        "Scenario: Scenario with commented line",
        "#Given I am first",
        "When I am second",
        "Then I am third"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Commented Step").should be_true
    scenario.rules_hash["Commented Step"].should == 1
  end

  it "should have record a rule occurrence and increment the score for each commented step in a scenario" do
    scenario_block = [
        "Scenario: Scenario with commented line",
        "#Given I am first",
        "#When I am second",
        "#Then I am third"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Commented Step").should be_true
    scenario.rules_hash["Commented Step"].should == 3
    scenario.score.should >= 9
  end

  it "should record a rule occurrence and increment the score of a scenario outline with a commented example row" do
    scenario_block = [
        "Scenario Outline: Scenario with commented line",
        "Given I am first",
        "When I am second",
        "Then I am third",
        "Examples:",
        "|var_a|",
        "#|a|",
        "|b|"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Commented Example").should be_true
    scenario.rules_hash["Commented Example"].should == 1
  end

  it "should record a rule occurrence and increment the score of a scenario outline with each commented example row" do
    scenario_block = [
        "Scenario Outline: Scenario with commented line",
        "Given I am first",
        "When I am second",
        "Then I am third",
        "Examples:",
        "|var_a|",
        "#|a|",
        "#|b|"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Commented Example").should be_true
    scenario.rules_hash["Commented Example"].should == 2
    scenario.score.should >= 6
  end

  it "should record a rule occurrence and increment the score of a scenario outline only no examples" do
    scenario_block = [
        "Scenario Outline: Scenario Outline with no examples",
        "Given I am first",
        "When I am second",
        "Then I am third",
        "Examples:",
        "|var_a|",
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Scenario Outline with only no examples").should be_true
    scenario.rules_hash["Scenario Outline with only no examples"].should == 1
  end

  it "should record a rule occurrence and increment the score of a scenario outline only one example" do
    scenario_block = [
        "Scenario Outline: Scenario Outline with one example",
        "Given I am first",
        "When I am second",
        "Then I am third",
        "Examples:",
        "|var_a|",
        "|a|"
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Scenario Outline with only one example").should be_true
    scenario.rules_hash["Scenario Outline with only one example"].should == 1
  end

  it "should record a rule occurrence and increment the score of a scenario outline without an examples table" do
    scenario_block = [
        "Scenario Outline: Scenario with no examples table",
        "Given I am first",
        "When I am second",
        "Then I am third",
    ]
    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Scenario Outline with no examples table").should be_true
    scenario.rules_hash["Scenario Outline with no examples table"].should == 1
  end

  it "should record a rule occurrence and increment the score of a scenario outline with too many examples" do
    scenario_block = [
        "Scenario Outline: Scenario with too many examples",
        "Given I am first",
        "When I am second",
        "Then I am third",
        "Examples:",
        "|var_a|"
    ]

    8.times{|n| scenario_block << "|#{n}|"}

    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Scenario Outline with too many examples").should be_true
    scenario.rules_hash["Scenario Outline with too many examples"].should == 1
  end

  it "should record a rule occurrence and increment the score of a scenario with too many tags" do
    scenario_block = []
    8.times{|n| scenario_block << "@tag_#{n}"}
    scenario_block << "Scenario: Scenario with many tags"

    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Scenario has too many tags").should be_true
    scenario.rules_hash["Scenario has too many tags"].should == 1
  end

  it "should record a rule occurrence with the word used and increment the score of a scenario with any implementation word" do
    scenario_block = [
        "Scenario: Scenario with implementation words",
        "Given I am on the login page",
        "When I log in to the site",
        "Then I am on the home page",
    ]

    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Implementation word used: page").should be_true
    scenario.rules_hash.include?("Implementation word used: site").should be_true
    scenario.rules_hash["Implementation word used: page"].should == 2
    scenario.rules_hash["Implementation word used: site"].should == 1
  end

  it "should record a rule occurrence with the date used and increment the score of a scenario with dates used" do
    scenario_block = [
        "Scenario: Scenario with dates used",
        "Given Today is 11/12/2013",
    ]

    scenario = Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Date used: 11/12/2013").should be_true
    scenario.rules_hash["Date used: 11/12/2013"].should == 1
  end
end