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
    file.puts("Scenario: My Other Test Scenario")
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
    @feature.tags.should == %w(@tag1 @tag2 @tag3)
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

  it "should have a score and rules of the feature and the scenarios contained in it" do
    @feature.score = 0
    @feature.rules_hash = {}

    my_scenario = Scenario.new("location:1", ["Scenario: Trigger a rule"])
    my_scenario.score = 1
    my_scenario.rules_hash = {"Rule Descriptor" => 1}
    @feature.scenarios[0] = my_scenario

    @feature.evaluate_score
    @feature.score.should == 1
    @feature.rules_hash.should == {"Rule Descriptor" => 1}
  end

  it "should add rules from the scenario independent of the feature rules" do
    scenario = @feature.scenarios[0]
    scenario.rules_hash = {"Scenario Rule" => 1}
    @feature.evaluate_score
    @feature.rules_hash.include?("Scenario Rule").should be_true
  end

  it "should have a rule and associated score for a descriptionless feature" do
    file = File.open(@file_name, "w")
    file.puts("Feature:")
    file.puts("")
    file.puts("Scenario: My Test Scenario")
    file.puts("Given I want to be a test")
    file.puts("When I become a test")
    file.puts("Then I am a test")
    file.close
    @feature = Feature.new(@file_name)
    @feature.rules_hash.include?("No Feature Description!").should be_true
    @feature.rules_hash["No Feature Description!"].should > 0
  end

  it "should have a rule and associated score for a feature without scenarios" do
    file = File.open(@file_name, "w")
    file.puts("Feature: I'm a feature without scenarios!")
    file.close
    @feature = Feature.new(@file_name)
    @feature.rules_hash.include?("Feature with no scenarios").should be_true
    @feature.rules_hash["Feature with no scenarios"].should > 0
  end

  it "should have a rule associated score for a feature with 10 or more scenarios" do
    file = File.open(@file_name, "w")
    file.puts("Feature: I'm a feature without scenarios!")
    10.times {file.puts "Scenario: I am a simple scenario"}
    file.close
    @feature = Feature.new(@file_name)
    @feature.rules_hash.include?("Feature with too many scenarios").should be_true
    @feature.rules_hash["Feature with too many scenarios"].should > 0
  end

  it "should have a rule associated score for a feature with any number" do
    file = File.open(@file_name, "w")
    file.puts("Feature: Story Card 12345")
    file.close
    @feature = Feature.new(@file_name)
    @feature.rules_hash.include?("Feature has number(s) in the title").should be_true
    @feature.rules_hash["Feature has number(s) in the title"].should > 0
  end

  it "should have a rule associated score for a feature with a very long description" do
    feature_description = ""
    180.times{feature_description << "A"}
    file = File.open(@file_name, "w")
    file.puts("Feature: #{feature_description}")
    file.close
    @feature = Feature.new(@file_name)
    @feature.rules_hash.include?("Feature title is too long").should be_true
    @feature.rules_hash["Feature title is too long"].should > 0
  end
end