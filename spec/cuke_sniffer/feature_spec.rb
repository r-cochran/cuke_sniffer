require 'spec_helper'
require 'cuke_sniffer/feature'

describe CukeSniffer::Feature do

  before(:each) do
    @file_name = "my_feature.feature"
    file = File.open(@file_name, "w")
    file.puts("Feature: I am a feature")
    file.puts ""
    file.close
  end

  after(:each) do
    delete_temp_files
  end

  it "should gather all feature tags" do
    pending('This test requires invalid Gherkin')

    feature_block = [
        "@tag1 @tag2",
        "@tag3", '#@tag4',
        "Feature: My Features are in this"
    ]
    build_file(feature_block, @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    feature.tags.should == ["@tag1", "@tag2", "@tag3", '#@tag4']
  end

  it "should parse a feature file and gather the feature name" do
    build_file(["Feature: My features are in this"], @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    feature.location.should == @file_name
    feature.name.should == "My features are in this"
  end

  it "should terminate when no Feature line and the end of file is reached" do
    build_file(["", "", ""], @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    feature.name.should == ""
  end

  it "should capture a feature description that spans multiple lines" do
    feature_block = [
        "Feature: I am a feature description",
        "that appears on multiple lines",
        "because it is legal in cucumber",
        ""
    ]
    build_file(feature_block, @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    feature.name.should == "I am a feature description that appears on multiple lines because it is legal in cucumber"
  end

  it "should parse Features files where there is no space between the 'Feature:' declaration and its description" do
    feature_block = [
        "Feature:Name"
    ]
    build_file(feature_block, @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    feature.name.should == "Name"
  end

  it "should be able to handle an empty feature file" do
    build_file([])
    CukeSniffer::Feature.new(@file_name)
  end

  it "should determine if it is above the feature threshold" do
    feature_block = [
        "Feature: ",
        "", "Scenario: ",
        "Given blah",
        "When blam",
        "Then blammo"
    ]
    build_file(feature_block, @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["Feature"]
    CukeSniffer::Constants::THRESHOLDS["Feature"] = 2
    feature.rules_hash = {"my rule" => 1}
    feature.score = 3
    feature.good?.should == false
    CukeSniffer::Constants::THRESHOLDS["Feature"] = start_threshold
  end

  it "should determine if it is below the feature threshold" do
    feature_block = [
        "Feature: ",
        "", "Scenario: ",
        "Given blah",
        "When blam",
        "Then blammo"
    ]
    build_file(feature_block, @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["Feature"]
    CukeSniffer::Constants::THRESHOLDS["Feature"] = 2
    feature.good?.should == true
    CukeSniffer::Constants::THRESHOLDS["Feature"] = start_threshold
  end

  it "should determine the percentage of problems compared to the feature threshold" do
    feature_block = [
        "Feature: ",
        "", "Scenario: ",
        "Given blah",
        "When blam",
        "Then blammo"
    ]
    build_file(feature_block, @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["Feature"]
    CukeSniffer::Constants::THRESHOLDS["Feature"] = 2
    feature.score = 3
    feature.problem_percentage.should == (3.0/2.0)
    CukeSniffer::Constants::THRESHOLDS["Feature"] = start_threshold
  end

  it "should not consider anything with an @ to be a symbol, it must always have a leading white space or nothing at all" do
    feature_block = [
        'Feature:',
        '',
        '    Scenario Outline:',
        '* a step',
        'Examples:',
        '    | param |',
        '    | !@#$% |'
    ]

    build_file(feature_block, @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    feature.scenarios.count.should == 1
    feature.scenarios.first.rules_hash.keys.include?("Scenario Outline with no examples.").should be_false
  end

  describe "Handling Backgrounds" do

    it "should capture a background in a feature" do
      feature_block = [
          "Feature: Feature with background",
          "Background: I am a background",
          "Given I want to be a test",
          "When I become a test",
          "Then I am a test"
      ]
      build_file(feature_block, @file_name)
      scenario = CukeSniffer::Scenario.new("#@file_name:3", feature_block)
      feature = CukeSniffer::Feature.new(@file_name)

      # todo - this line does nothing...
      feature.background == scenario

      feature.scenarios.empty?.should == true
    end

  end

  describe "Handling Scenarios" do

    it "can create a feature file without scenarios" do
      feature_block = [
          "Feature: I am a feature without scenarios",
          ""
      ]
      build_file(feature_block, @file_name)
      feature = CukeSniffer::Feature.new(@file_name)
      feature.scenarios.should == []
    end

    it "should should not lose the tags of the first scenario when rules are ran." do
      feature_block = [
          "Feature: I'm a feature with scenarios with identical tags!",
          "",
          "@tag",
          "@a",
          "@test",
          "Scenario: Scenario 1",
          "@tag @a",
          "Scenario: Scenario 2",
          "@tag",
          "Scenario: Scenario 3"
      ]
      build_file(feature_block, @file_name)
      feature = CukeSniffer::Feature.new(@file_name)
      feature.scenarios.first.tags.should == ["@tag", "@a", "@test"]
    end

    it "should only consider cucumber formatted Scenarios and Scenario Outlines when generating scenario objects" do
      feature_block = [
          "Feature:",
          "",
          "    Manual Scenario: this is not a test",
          "",
          "    Previously Tested Scenario: nope, still just hanging out in the feature description zone",
          "",
          " Scenario: Real Scenario",
          "* step"
      ]
      build_file(feature_block, @file_name)
      feature = CukeSniffer::Feature.new(@file_name)
      feature.scenarios.count.should == 1
      feature.scenarios.first.name.should == "Real Scenario"
    end

    it "should not throw an error on a scenario outline followed by multiple examples tables with tags included" do
      feature_block = [
          "Feature: Just a plain old feature",
          "Scenario Outline: Outlinable",
          "Given <outline>",
          "Examples:",
          "| outline |",
          "| things |",
          "@tag",
          "Examples:",
          "| outline |",
          "| stuff |"
      ]
      build_file(feature_block, @file_name)
      expect { CukeSniffer::Feature.new(@file_name) }.to_not raise_error
    end
  end

end

describe "FeatureRules" do

  def run_rule_against_feature(feature_block, rule)
    build_file(feature_block)
    @cli.features = [CukeSniffer::Feature.new(@file_name)]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])

  end

  def test_feature_rule(feature_block, symbol, count = 1)
    rule = CukeSniffer::CukeSnifferHelper.build_rule(symbol, RULES[symbol])
    run_rule_against_feature(feature_block, rule)
    rule.phrase.gsub!("{class}", "Feature")
    verify_rule(@cli.features.first, rule, count)
  end

  def test_no_feature_rule(feature_block, symbol)
    rule = CukeSniffer::CukeSnifferHelper.build_rule(symbol, RULES[symbol])
    run_rule_against_feature(feature_block, rule)
    rule.phrase.gsub!("{class}", "Feature")
    verify_no_rule(@cli.features.first, rule)
  end

  before(:each) do
    @file_name = "my_feature.feature"
    @cli = CukeSniffer::CLI.new()
  end

  after(:each) do
    delete_temp_files
  end

  it "should punish Features with no content" do
    feature_block = []
    test_feature_rule(feature_block, :empty_feature)
  end

  it "should punish Features with too many tags" do
    feature_block = []
    RULES[:too_many_tags][:max].times { |n| feature_block << "@tag_#{n}" }
    feature_block << "Feature: Feature with many tags"
    test_feature_rule(feature_block, :too_many_tags)
  end

  it "should punish Features without a name" do
    feature_block = [
        "Feature:"
    ]
    test_feature_rule(feature_block, :no_description)
  end

  it "should punish Features with numbers in its name" do
    feature_block = ["Feature: Story Card 12345"]
    test_feature_rule(feature_block, :numbers_in_description)
  end

  it "should punish Features with long names" do
    feature_description = ""
    RULES[:long_name][:max].times { feature_description << "A" }
    feature_block = ["Feature: #{feature_description}"]
    test_feature_rule(feature_block, :long_name)
  end

  it "should punish Features that have a background but no Scenarios" do
    feature_block = [
        "Feature: Feature with background and no scenarios",
        "",
        "Background: I am a background",
        "And I want to be a test"
    ]
    test_feature_rule(feature_block, :background_with_no_scenarios)
  end

  it "should punish Features that have a background and only one Scenario" do
    feature_block = [
        "Feature: Feature with background and one scenario",
        "",
        "Background: I am a background",
        "And I want to be a test",
        "",
        "Scenario: One Scenario"
    ]
    test_feature_rule(feature_block, :background_with_one_scenario)
  end

  it "should punish Features with zero Scenarios" do
    feature_block = [
        "Feature: I'm a feature without scenarios"
    ]
    test_feature_rule(feature_block, :no_scenarios)
  end

  it "should punish Features with too many Scenarios" do
    feature_block = [
        "Feature: I'm a feature without scenarios!"
    ]
    RULES[:too_many_scenarios][:max].times { feature_block << "Scenario: I am a simple scenario" }
    test_feature_rule(feature_block, :too_many_scenarios)
  end

  it "should punish Features if all of the feature and any scenario have a common tag." do
    feature_block = [
      "@tag",
      "Feature: I'm a feature with scenarios with identical tags!",
      "",
      "Scenario: I have the same tag1",
      "@tag",
      "Scenario: I have the same tag2"
    ]
    test_feature_rule(feature_block, :feature_same_tag)
  end

  it "should punish Features if all of the scenarios have a common tag. Simple." do
    feature_block = [
        "Feature: I'm a feature with scenarios with identical tags!",
        "",
        "@tag",
        "Scenario: I have the same tag1",
        "@tag",
        "Scenario: I have the same tag2"
    ]
    test_feature_rule(feature_block, :scenario_same_tag)
  end

  it "should punish Features if all of the scenarios have a common tag. Complex" do
    feature_block = [
        "Feature: I'm a feature with scenarios with identical tags!",
        "",
        "@tag @a",
        "Scenario: I have the same tag1",
        "@tag @tag2 @tag3",
        "@a",
        "Scenario: I have the same tag2"
    ]
    test_feature_rule(feature_block, :scenario_same_tag, 2)
  end

  it "should punish Features if the description has commas in it." do
    feature_block = [
        "Feature: I'm a feature with scenarios with a comma, in the description",
        "",
        "Scenario: I am a Scenario"
    ]
    test_feature_rule(feature_block, :commas_in_description)
  end

  it "should punish Features that have a comment on a line after a tag" do
    pending('This test requires invalid Gherkin')

    feature_block = [
        "@tag",
        "#comment",
        "     #comment with spaces",
        "Feature: I'm a feature with a comment after a tag"
    ]
    test_feature_rule(feature_block, :comment_after_tag)
  end

  it "should not punish Features that have a tag with a hash in it" do
    feature_block = [
        "@tag",
        "@#comment",
        "Feature: I'm a feature with a hash symbol in my tag"
    ]
    test_no_feature_rule(feature_block, :comment_after_tag)
  end

  it "should punish Features that have commented tags" do
    pending('fix comment based tests last')

    feature_block = [
        '#@tag',
        "Feature: I'm a feature with a commented tag"
    ]
    test_feature_rule(feature_block, :commented_tag)
  end

  it "should not punish Features that have a comment before any tags occur" do
    feature_block = [
        "#comment",
        "@tag",
        "Feature: I'm a feature with a comment before a tag"
    ]
    test_no_feature_rule(feature_block, :comment_after_tag)
  end

end
