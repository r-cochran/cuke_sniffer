require 'spec_helper'

describe CukeSniffer::Feature do

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

  def build_file(lines)
    file = File.open(@file_name, "w")
    lines.each{|line| file.puts(line)}
    file.close
  end

  it "should parse a feature file and gather the feature name" do
    build_file(["Feature: My features are in this"])
    feature = CukeSniffer::Feature.new(@file_name)
    feature.location.should == @file_name
    feature.name.should == "My features are in this"
  end

  it "should capture a feature description that spans multiple lines" do
    build_file(["Feature: I am a feature description", "that appears on multiple lines", "because it is legal in cucumber", ""])
    feature = CukeSniffer::Feature.new(@file_name)
    feature.name.should == "I am a feature description that appears on multiple lines because it is legal in cucumber"
  end

  it "should  parse Features files where there is no space between the 'Feature:' declaration and its description" do
    build_file(%w(Feature:Name))
    feature = CukeSniffer::Feature.new(@file_name)
    feature.name.should == "Name"
  end

  it "should gather all feature tags" do
    build_file(["@tag1 @tag2", "@tag3", '#@tag4', "Feature: My Features are in this"])
    feature = CukeSniffer::Feature.new(@file_name)
    feature.tags.should == ["@tag1", "@tag2", "@tag3", '#@tag4']
  end

  it "should capture a background in a feature" do
    raw_code = [
                "Background: I am a background",
                "Given I want to be a test",
                "When I become a test",
                "Then I am a test"
               ]
    build_file(["Feature: Feature with background", "", [raw_code]].flatten)
    scenario = CukeSniffer::Scenario.new("#@file_name:3", raw_code)
    feature = CukeSniffer::Feature.new(@file_name)
    feature.background == scenario
    feature.scenarios.empty?.should == true
  end

  it "can create a feature file without scenarios" do
    build_file(["Feature: I am a feature without scenarios", ""])
    feature = CukeSniffer::Feature.new(@file_name)
    feature.scenarios.should == []
  end

  it "should have access to feature specific rules" do
    build_file(["Feature: ", "", "Scenario: ", "Given blah", "When blam", "Then blammo"])
    feature = CukeSniffer::Feature.new(@file_name)
    feature.rules_hash.should == {"Feature has no description." => 1}
  end

  it "should determine if it is above the feature threshold" do
    build_file(["Feature: ", "", "Scenario: ", "Given blah", "When blam", "Then blammo"])
    feature = CukeSniffer::Feature.new(@file_name)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["Feature"]
    CukeSniffer::Constants::THRESHOLDS["Feature"] = 2
    feature.good?.should == false
    CukeSniffer::Constants::THRESHOLDS["Feature"] = start_threshold
  end

  it "should determine if it is below the feature threshold" do
    build_file(["Feature: I am a feature", "", "Scenario: ", "Given blah", "When blam", "Then blammo"])
    feature = CukeSniffer::Feature.new(@file_name)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["Feature"]
    CukeSniffer::Constants::THRESHOLDS["Feature"] = 2
    feature.good?.should == true
    CukeSniffer::Constants::THRESHOLDS["Feature"] = start_threshold
  end

  it "should determine the percentage of problems compared to the feature threshold" do
    build_file(["Feature: I am a feature", "", "Scenario: ", "Given blah", "When blam", "Then blammo"])
    feature = CukeSniffer::Feature.new(@file_name)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["Feature"]
    CukeSniffer::Constants::THRESHOLDS["Feature"] = 2
    feature.score = 3
    feature.problem_percentage.should == (3.0/2.0)
    CukeSniffer::Constants::THRESHOLDS["Feature"] = start_threshold
  end

end

describe "FeatureRules" do

  before(:each) do
    @file_name = "my_feature.feature"
  end

  after(:each) do
    File.delete(@file_name)
  end

  def build_file(lines)
    file = File.open(@file_name, "w")
    lines.each{|line| file.puts(line)}
    file.close
  end

  def validate_rule(feature, rule)
    phrase = rule[:phrase].gsub(/{.*}/, "Feature")

    feature.rules_hash.should include phrase
    feature.rules_hash[phrase].should > 0
    feature.score.should >= rule[:score]
  end

  it "should punish Features with too many tags" do
    rule = SHARED_RULES[:too_many_tags]

    lines = []
    rule[:max].times { |n| lines << "@tag_#{n}" }
    lines << "Feature: Feature with many tags"
    build_file(lines)
    feature = CukeSniffer::Feature.new(@file_name)

    validate_rule(feature, rule)
  end

  it "should punish Features without a name" do
    build_file(%w(Feature:))
    feature = CukeSniffer::Feature.new(@file_name)

    validate_rule(feature, SHARED_RULES[:no_description])
  end

  it "should punish Features with numbers in its name" do
    build_file(["Feature: Story Card 12345"])
    feature = CukeSniffer::Feature.new(@file_name)

    validate_rule(feature, SHARED_RULES[:numbers_in_description])
  end

  it "should punish Features with long names" do
    rule = SHARED_RULES[:long_name]

    feature_description = ""
    rule[:max].times { feature_description << "A" }
    build_file(["Feature: #{feature_description}"])
    feature = CukeSniffer::Feature.new(@file_name)

    validate_rule(feature, rule)
  end

  it "should punish Features that have a background but no Scenarios" do
    build_file(["Feature: Feature with background and no scenarios", "", "Background: I am a background", "And I want to be a test"])
    feature = CukeSniffer::Feature.new(@file_name)
    validate_rule(feature, FEATURE_RULES[:background_with_no_scenarios])
  end

  it "should punish Features that have a background and only one Scenario" do
    build_file(["Feature: Feature with background and one scenario", "", "Background: I am a background", "And I want to be a test", "", "Scenario: One Scenario"])
    feature = CukeSniffer::Feature.new(@file_name)
    validate_rule(feature, FEATURE_RULES[:background_with_one_scenario])
  end

  it "should punish Features with zero Scenarios" do
    build_file(["Feature: I'm a feature without scenarios"])
    feature = CukeSniffer::Feature.new(@file_name)
    validate_rule(feature, FEATURE_RULES[:no_scenarios])
  end

  it "should punish Features with too many Scenarios" do
    rule = FEATURE_RULES[:too_many_scenarios]

    lines = ["Feature: I'm a feature without scenarios!"]
    rule[:max].times { lines << "Scenario: I am a simple scenario" }

    build_file(lines)
    feature = CukeSniffer::Feature.new(@file_name)
    validate_rule(feature, rule)
  end

end
