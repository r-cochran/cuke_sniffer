require 'spec_helper'
require 'cuke_sniffer/scenario'

describe CukeSniffer::Scenario do

  after(:all) do
    delete_temp_files
  end

  it "should retain the passed location, name, and the steps of the scenario step after initialization" do
    scenario_block = [
        "Scenario: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    location = "path/path/path/my_feature.feature:1"
    step_definition = CukeSniffer::Scenario.new(location, scenario_block)
    step_definition.location.should == location
    step_definition.name.should == "Test Scenario"
    step_definition.steps.should == [
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made"
    ]
  end

  it "should retain the information from scenario outlines" do
    scenario_block = [
        "Scenario Outline: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    location = "path/path/path/my_feature.feature:1"
    step_definition = CukeSniffer::Scenario.new(location, scenario_block)
    step_definition.location.should == location
    step_definition.name.should == "Test Scenario"
    step_definition.steps.should == [
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made"
    ]
  end

  it "should retain the information from scenario templates" do
    scenario_block = [
        "Scenario Template: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    location = "path/path/path/my_feature.feature:1"
    step_definition = CukeSniffer::Scenario.new(location, scenario_block)
    step_definition.location.should == location
    step_definition.name.should == "Test Scenario"
    step_definition.steps.should == [
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made"
    ]
  end

  it "should retain information on a tagged scenario" do
    pending('This test requires invalid Gherkin')

    scenario_block = [
        "@tag1 @tag2",
        "@tag3",
        "#comment before scenario",
        "Scenario: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    location = "path/path/path/my_feature.feature:1"
    step_definition = CukeSniffer::Scenario.new(location, scenario_block)
    step_definition.location.should == location
    step_definition.name.should == "Test Scenario"
    step_definition.tags.should == [
        "@tag1",
        "@tag2",
        "@tag3",
        "#comment before scenario"
    ]
    step_definition.steps.should == [
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made"
    ]
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
    scenario = CukeSniffer::Scenario.new(location, scenario_block)
    scenario.location.should == location
    scenario.name.should == "Test Scenario"
    scenario.steps.should == [
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made"
    ]
    scenario.examples_table.should == [
        "| stuff |",
        "| a |"
    ]
  end

  it "should retain the type of scenario" do
    scenario_block = [
        "Scenario: Test Scenario",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.type.should == "Scenario"
  end

  it "should retain the type of scenario outline" do
    scenario_block = [
        "Scenario Outline: Test Scenario",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.type.should == "Scenario Outline"
  end

  it "should return the name for multi-line scenarios" do
    scenario_block = [
        "Scenario: Test",
        "My",
        "Multi-line",
        "Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.name.should == "Test My Multi-line Scenario"
  end

  it "should only include examples in the examples table and not white space" do
    pending('non-behavioral test. new implementation safely breaks it')

    scenario_block = [
        "Scenario Outline: Examples table should not keep white space or comments",
        "Examples:",
        "|var_name|",
        "|one|",
        "#|two|",
        "",
        "|three|",
        ""
    ]

    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.examples_table.should == ["|var_name|", "|one|", "#|two|", "|three|"]
  end

  it "should only include steps and not white space" do
    pending('non-behavioral test. new implementation safely breaks it')

    scenario_block = [
        "Scenario: Examples table should not keep white space or comments",
        "Given I am a thing",
        "And I am also a thing",
        "",
        "#      When I skip a line",
        "",
        "#hi",
        "Then I should have an interesting scenario",
        ""
    ]

    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.steps.should == [
        "Given I am a thing",
        "And I am also a thing",
        "#      When I skip a line",
        "Then I should have an interesting scenario"
    ]
  end

  it "should capture a scenario even if it commented out" do
    pending('non-behavioral test. new implementation safely breaks it')

    scenario_block = [
        "# Scenario: I am a commented Scenario",
        "# Given I am commented",
        "When I am commented",
        "#Then we are all commented"
    ]

    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.name.should == "I am a commented Scenario"
  end

  it "should capture inline tables and associate them with the step using the table" do
    scenario_block = [
        "Scenario: It has an inline table",
        "Given the in line table is here",
        "|one|two|three|",
        "|1|2|3|"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.inline_tables["Given the in line table is here"].should == ["| one | two | three |", "| 1 | 2 | 3 |"]
  end

  it "should not clip steps after an inline table" do
    scenario_block = [
        "Scenario: It has an inline table",
        "Given the in line table is here",
        "|one|two|three|",
        "|1|2|3|",
        "And I am still here"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.steps.should == [
        "Given the in line table is here",
        "And I am still here"
    ]
  end

  it "should not clip steps after multiple inline table" do
    scenario_block = [
        "Scenario: It has an inline table",
        "Given the in line table is here",
        "|one|two|three|",
        "|1|2|3|",
        "And I am still here",
        "| are you sure |",
        "| really sure |",
        "Then I am at the end"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.steps.should == [
        "Given the in line table is here",
        "And I am still here",
        "Then I am at the end"
    ]
  end

  it "should determine if it is above the scenario threshold" do
    scenario_block = ["Scenario: Above scenario threshold"]

    start_threshold = CukeSniffer::Constants::THRESHOLDS["Scenario"]
    CukeSniffer::Constants::THRESHOLDS["Scenario"] = 2
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.score = 3
    scenario.good?.should == false
    CukeSniffer::Constants::THRESHOLDS["Scenario"] = start_threshold
  end

  it "should determine if it is below the scenario threshold" do
    scenario_block = [
        "Scenario: Below scenario threshold",
        "Given I am a good scenario",
        "When I do a behavior inducing action",
        "Then that action is verified"
    ]

    start_threshold = CukeSniffer::Constants::THRESHOLDS["Scenario"]
    CukeSniffer::Constants::THRESHOLDS["Scenario"] = 2
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.good?.should == true
    CukeSniffer::Constants::THRESHOLDS["Scenario"] = start_threshold
  end

  it "should determine the percentage of problems compared to the scenario threshold" do
    scenario_block = [
        "Scenario: Above scenario threshold",
        "#Given I am a good scenario",
        "#When I do a behavior inducing action",
        "#Then that action is verified"
    ]

    start_threshold = CukeSniffer::Constants::THRESHOLDS["Scenario"]
    CukeSniffer::Constants::THRESHOLDS["Scenario"] = 2
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.score = 3
    scenario.problem_percentage.should == (3.0/2.0).to_f
    CukeSniffer::Constants::THRESHOLDS["Scenario"] = start_threshold
  end

  it "should not have inline tables overflow to include the examples table" do
    scenario_block = [
        'Scenario Outline:',
        '* a step',
        '| row 1 |',
        '| row 2 |',
        '| row 3 |',
        'Examples:',
        '| param |',
        '| value1 |',
        '| value2 |'
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.examples_table.should == [
        "| param |",
        "| value1 |",
        "| value2 |"
    ]
  end

  it "should not pick up commented non-example lines in an example table" do
    scenario_block = [
        "Scenario Outline: Commented examples",
        "* step",
        "Examples:",
        "| thing |",
        "#a comment",
        "| 2 |"
    ]
    scenario = CukeSniffer::Scenario.new("Location.rb:1", scenario_block)
    scenario.examples_table.should == [
        "| thing |",
        "| 2 |"
    ]
  end

  # todo - copy/pasted name of test does not match test goal
  it "should not pick up commented non-example lines in an example table" do
    pending('non-behavioral test. new implementation safely breaks it')

    scenario_block = [
        "Scenario Outline: Commented example",
        "* step",
        "Examples:",
        "| thing |",
        "#| 2 |"
    ]
    scenario = CukeSniffer::Scenario.new("Location.rb:1", scenario_block)
    scenario.examples_table.should == [
        "| thing |",
        "#| 2 |"
    ]
  end

  it "should not keep the line following additional example tables on a scenario" do
    scenario_block = ["Scenario Outline: Outlinable",
        "Given <outline>",
        "Examples:",
        "| outline |",
        "| things |",
        "@tag",
        "Examples:",
        "| outline |",
        "| stuff |",
        "Examples:",
        "| outline |",
        "| thing 1 |",
        "| thing 2 |"
    ]

    scenario = CukeSniffer::Scenario.new("location.rb:1", scenario_block)
    scenario.examples_table.should == [
        "| outline |",
        "| things |",
        "| stuff |",
        "| thing 1 |",
        "| thing 2 |"
    ]

  end

  it "should not remove example items that are the same as the variable name" do
    scenario_block = [
        "Scenario Outline: Outlinable",
        "Given <outline>",
        "Examples:",
        "| outline |",
        "| things |",
        "| outline |"
    ]

    scenario = CukeSniffer::Scenario.new("location.rb:1", scenario_block)
    scenario.examples_table.should == [
        "| outline |",
        "| things |",
        "| outline |"
    ]
  end

  describe "#outline?" do
    it "returns true when type is 'Scenario Outline'" do
      scenario_block = [
          "Scenario Outline: Test Scenario",
      ]
      location = "path/path/path/my_feature.feature:1"
      scenario = CukeSniffer::Scenario.new(location, scenario_block)
      scenario.outline?.should be_true
    end

    it "returns false when the type is 'Scenario'" do
      scenario_block = [
          "Scenario: Test Scenario",
      ]
      location = "path/path/path/my_feature.feature:1"
      scenario = CukeSniffer::Scenario.new(location, scenario_block)
      scenario.outline?.should be_false
    end

    it "returns false when the type is 'Background'" do
      scenario_block = [
          "Background: Test Scenario",
      ]
      location = "path/path/path/my_feature.feature:1"
      scenario = CukeSniffer::Scenario.new(location, scenario_block)
      scenario.outline?.should be_false
    end
  end

  describe "#commented_examples" do
    it "returns a commented example" do
      feature_block = [
          'Feature:',
          "Scenario Outline: Test Scenario",
          "Given I need a <animal>",
          "Examples:",
          "|animal|",
          "|cat|",
          "#|dog|",
          "#|gerbil|"
      ]
      @file_name = 'foo.feature'

      build_file(feature_block, @file_name)
      feature = CukeSniffer::Feature.new(@file_name)
      delete_temp_files

      feature.scenarios.first.commented_examples.should == ["#|dog|", "#|gerbil|"]
    end

    it "returns an empty array when there are no commented examples" do
      feature_block = [
          'Feature:',
          "Scenario Outline: Test Scenario",
          "Given I need a <animal>",
          "Examples:",
          "|animal|",
          "|cat|",
          "|dog|",
          "|gerbil|"
      ]
      @file_name = 'foo.feature'

      build_file(feature_block, @file_name)
      feature = CukeSniffer::Feature.new(@file_name)
      delete_temp_files

      scenario = feature.scenarios.first

      scenario.commented_examples.should == []
    end

    it "returns empty list when there are no examples" do
      feature_block = [
          'Feature:',
          "Scenario: Test Scenario",
          "Given I need a animal",
      ]
      @file_name = 'foo.feature'

      build_file(feature_block, 'foo.feature')
      feature = CukeSniffer::Feature.new(@file_name)
      delete_temp_files

      scenario = feature.scenarios.first

      scenario.commented_examples.should == []
    end
  end

  describe "#get_steps" do
    it "returns all steps associated with a step style" do
      scenario_block = [
          "Scenario: Multiple Givens",
          "Given I am doing setup",
          "Given I am doing more setup",
      ]
      location = "path/path/path/my_feature.feature:1"
      scenario = CukeSniffer::Scenario.new(location, scenario_block)
      scenario.get_steps("Given").size.should == 2
    end

    it "returns an empty list if there are no step styles associated" do
      scenario_block = [
          "Scenario: Multiple Givens",
          "Given I am doing setup",
          "Given I am doing more setup",
      ]
      location = "path/path/path/my_feature.feature:1"
      scenario = CukeSniffer::Scenario.new(location, scenario_block)
      scenario.get_steps("Then").size.should == 0
    end

    it "can handle the * step starter" do
      scenario_block = [
          "Scenario: Multiple Givens",
          "Given I am doing setup",
          "* I am doing more setup",
      ]
      location = "path/path/path/my_feature.feature:1"
      scenario = CukeSniffer::Scenario.new(location, scenario_block)
      scenario.get_steps("*").size.should == 1
    end
  end


end

describe "ScenarioRules" do

  def run_rule_against_scenario(scenario_block, rule)
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    build_file([], @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    delete_temp_files
    feature.scenarios =[scenario]
    @cli.features = [feature]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
  end

  def test_scenario_rule(scenario_block, symbol, count = 1)
    rule = CukeSniffer::CukeSnifferHelper.build_rule(symbol, RULES[symbol])
    run_rule_against_scenario(scenario_block, rule)
    rule.phrase.gsub!("{class}", "Scenario")
    verify_rule(@cli.features.first.scenarios.first, rule, count)
  end

  def test_no_scenario_rule(scenario_block, symbol)
    rule = CukeSniffer::CukeSnifferHelper.build_rule(symbol, RULES[symbol])
    run_rule_against_scenario(scenario_block, rule)
    rule.phrase.gsub!("{class}", "Scenario")
    verify_no_rule(@cli.features.first.scenarios.first, rule)
  end

  before(:each) do
    @file_name = "my_feature.feature"
    @cli = CukeSniffer::CLI.new()
  end

  after(:all) do
    delete_temp_files
  end

  it "should punish Scenarios without a name" do
    scenario_block = [
        "Scenario:"
    ]
    test_scenario_rule(scenario_block, :no_description)
  end

  it "should punish Scenarios with no steps" do
    scenario_block = [
        "Scenario: Empty Scenario"
    ]
    test_scenario_rule(scenario_block, :no_steps)
  end

  it "should punish Scenarios with numbers in its name" do
    scenario_block = [
        "Scenario: Scenario with some digits 123"
    ]
    test_scenario_rule(scenario_block, :numbers_in_description)
  end

  it "should punish Scenarios with long names" do
    scenario_description = ""
    RULES[:long_name][:max].times { scenario_description << "A" }
    scenario_block = [
        "Scenario: #{scenario_description}"
    ]
    test_scenario_rule(scenario_block, :long_name)
  end

  it "should punish Scenarios with too many steps" do
    scenario_block = [
        "Scenario: Scenario with too many steps"
    ]
    (RULES[:too_many_steps][:max]+1).times { scenario_block << "And I have too many steps" }
    test_scenario_rule(scenario_block, :too_many_steps)
  end

  it "should punish Scenarios with steps that are out of order: Then/When" do
    scenario_block = [
        "Scenario: Scenario with out of order steps",
        "Then comes first",
        "When comes second"
    ]
    test_scenario_rule(scenario_block, :out_of_order_steps)
  end

  it "should punish Scenarios with steps that are out of order: Then/When/Given" do
    scenario_block = [
        "Scenario: Scenario with out of order steps",
        "Then comes first",
        "When comes second",
        "Given comes third"
    ]
    test_scenario_rule(scenario_block, :out_of_order_steps)
  end

  it "should punish Scenarios with steps that are out of order: Given/Then/And/When" do
    scenario_block = [
        "Scenario: Scenario with out of order steps",
        "Given comes first",
        "Then comes second",
        "And is ignored",
        "When comes third"
    ]
    test_scenario_rule(scenario_block, :out_of_order_steps)
  end

  it "should punish Scenarios with And as its first step" do
    scenario_block = [
        "Scenario: Scenario with And as its first step",
        "And is not a valid first step",
    ]
    test_scenario_rule(scenario_block, :invalid_first_step)
  end

  it "should punish Scenarios with But as its first step" do
    scenario_block = [
        "Scenario: Scenario with But as its first step",
        "But is not a valid first step",
        "When comes first"
    ]
    test_scenario_rule(scenario_block, :invalid_first_step)
  end

  it "should punish Scenarios that use the * step" do
    scenario_block = [
        "Scenario: Scenario with *",
        "* is an awesome operator"
    ]
    test_scenario_rule(scenario_block, :asterisk_step)
  end

  it "should punish each step in a Scenario that uses *" do
    scenario_block = [
        "Scenario: Scenario with *",
        "Given I am first",
        "* is an awesome operator",
        "When I am second",
        "* is an awesome operator",
        "Then I am third"
    ]
    test_scenario_rule(scenario_block, :asterisk_step, 2)
  end

  it "should punish Scenarios with commented steps" do
    feature_block = [
        'Feature:',
        "Scenario: Scenario with commented line",
        "#Given I am first",
        "When I am second",
        "Then I am third"
    ]
    @file_name = 'foo.feature'

    rule = CukeSniffer::CukeSnifferHelper.build_rule(:commented_step, RULES[:commented_step])
    build_file(feature_block, @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    delete_temp_files
    @cli.features = [feature]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    verify_rule(@cli.features.first.scenarios.first, rule, 1)
  end

  it "should punish each step in a Scenario that is commented" do
    feature_block = [
        'Feature:',
        "Scenario: Scenario with commented line",
        "#Given I am first",
        "#When I am second",
        "#Then I am third",
        'Scenario: Just an extra scenario to make sure that comments are not lost in gherkin 2.x'
    ]
    @file_name = 'foo.feature'

    rule = CukeSniffer::CukeSnifferHelper.build_rule(:commented_step, RULES[:commented_step])
    build_file(feature_block, @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    delete_temp_files
    @cli.features = [feature]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    verify_rule(@cli.features.first.scenarios.first, rule, 3)
  end

  it "should punish Scenario Outlines with commented examples" do
    feature_block = [
        'Feature:',
        "Scenario Outline: Scenario with commented line",
        "Given I am first",
        "When I am second",
        "Then I am third",
        "Examples:",
        "|var_a|",
        "#|a|",
        "|b|"
    ]
    @file_name = 'foo.feature'

    rule = CukeSniffer::CukeSnifferHelper.build_rule(:commented_example, RULES[:commented_example])
    build_file(feature_block, @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    delete_temp_files
    @cli.features = [feature]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    verify_rule(@cli.features.first.scenarios.first, rule, 1)
  end

  it "should punish each commented example in a Scenario Outline" do
    feature_block = [
        'Feature:',
        "Scenario Outline: Scenario with commented line",
        "Given I am first",
        "When I am second",
        "Then I am third",
        "Examples:",
        "|var_a|",
        "#|a|",
        "#|b|"
    ]
    @file_name = 'foo.feature'

    rule = CukeSniffer::CukeSnifferHelper.build_rule(:commented_example, RULES[:commented_example])
    build_file(feature_block, @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    delete_temp_files
    @cli.features = [feature]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    verify_rule(@cli.features.first.scenarios.first, rule, 2)
  end

  it "should punish Scenario Outlines with no examples" do
    scenario_block = [
        "Scenario Outline: Scenario Outline with no examples",
        "Given I am first",
        "When I am second",
        "Then I am third",
        "Examples:",
        "|var_a|",
    ]
    test_scenario_rule(scenario_block, :no_examples)
  end

  it "should punish Scenario Outlines with only one example" do
    scenario_block = [
        "Scenario Outline: Scenario Outline with one example",
        "Given I am first",
        "When I am second",
        "Then I am third",
        "Examples:",
        "|var_a|",
        "|a|"
    ]
    test_scenario_rule(scenario_block, :one_example)
  end

  it "should punish Scenario Outlines without the Examples table" do
    scenario_block = [
        "Scenario Outline: Scenario with no examples table",
        "Given I am first",
        "When I am second",
        "Then I am third",
    ]
    test_scenario_rule(scenario_block, :no_examples_table)
  end

  it "should punish Scenario Outlines with too many examples" do
    rule = RULES[:too_many_examples]
    scenario_block = [
        "Scenario Outline: Scenario with too many examples",
        "Given I am first",
        "When I am second",
        "Then I am third",
        "Examples:",
        "|var_a|"
    ]
    rule[:max].times { |n| scenario_block << "|#{n}|" }
    test_scenario_rule(scenario_block, :too_many_examples)
  end

  it "should punish Scenarios with too many tags" do
    scenario_block = []
    RULES[:too_many_tags][:max].times { |n| scenario_block << "@tag_#{n}" }
    scenario_block << "Scenario: Scenario with many tags"
    test_scenario_rule(scenario_block, :too_many_tags)
  end

  it "should punish Scenarios that use implementation words(page/site/ect)" do
    scenario_block = [
        "Scenario: Scenario with implementation words",
        "Given I am on the login page",
        "When I log in to the site",
        "Then I am on the home page",
    ]
    rule = CukeSniffer::CukeSnifferHelper.build_rule(:implementation_word, RULES[:implementation_word])
    run_rule_against_scenario(scenario_block, rule)
    scenario = @cli.features[0].scenarios[0]

    scenario.rules_hash.include?("Implementation word used: page.").should be_true
    scenario.rules_hash.include?("Implementation word used: site.").should be_true
    scenario.rules_hash["Implementation word used: page."].should == 2
    scenario.rules_hash["Implementation word used: site."].should == 1
  end

  it "should not punish Scenarios that use the word table for the tab implementation word" do
    scenario_block = [
        "Scenario: Scenario with implementation words",
        "Given there is fruit on a table",
        "When check the table for fruit",
        "Then I find an apple",
    ]
    rule = CukeSniffer::CukeSnifferHelper.build_rule(:implementation_word, RULES[:implementation_word])
    run_rule_against_scenario(scenario_block, rule)
    scenario = @cli.features[0].scenarios[0]

    scenario.rules_hash.include?("Implementation word used: tab.").should_not be_true
  end

  it "should punish Scenarios with steps that use fixed Dates(01/01/0001)" do
    scenario_block = [
        "Scenario: Scenario with dates used",
        "Given Today is 11/12/2013",
    ]
    test_scenario_rule(scenario_block, :date_used)
  end

  it "should punish Scenario steps with only one word." do
    scenario_block = [
        "Scenario: Step with one word",
        "Given word",
    ]
    test_scenario_rule(scenario_block, :one_word_step)
  end

  it "should punish Scenarios with multiple steps with only one word." do
    scenario_block = [
        "Scenario: Step with one word",
        "Given word",
        "When nope",
    ]
    test_scenario_rule(scenario_block, :one_word_step, 2)
  end

  it "should punish Scenarios that use Given more than once." do
    scenario_block = [
        "Scenario: Multiple Givens",
        "Given I am doing setup",
        "Given I am doing more setup",
    ]
    test_scenario_rule(scenario_block, :multiple_given_when_then)
  end

  it "should punish Scenarios that use When more than once." do
    scenario_block = [
        "Scenario: Multiple Givens",
        "When I am doing setup",
        "When I am doing more setup",
    ]
    test_scenario_rule(scenario_block, :multiple_given_when_then)
  end

  it "should punish Scenarios that use Then more than once." do
    scenario_block = [
        "Scenario: Multiple Givens",
        "Then I am doing setup",
        "Then I am doing more setup",
    ]
    test_scenario_rule(scenario_block, :multiple_given_when_then)
  end

  it "should punish Scenarios that have commas in its description" do
    scenario_block = ["Scenario: Scenario with a comma, in its description"]
    test_scenario_rule(scenario_block, :commas_in_description)
  end

  it "should punish Scenarios that have a comment on a line after a tag" do
    pending('this behavior is not really doable anymore. replace')

    scenario_block = [
        "@tag",
        "#comment",
        "     #comment with spaces",
        "Scenario: Comment after Tag",
        "Given I am a step"
    ]
    test_scenario_rule(scenario_block, :comment_after_tag)
  end

  it "should not punish Scenarios that have a tag with a hash in it" do
    scenario_block = [
        "@tag",
        "@#comment",
        "Scenario: Comment after Tag",
        "Given I am a step"
    ]
    test_no_scenario_rule(scenario_block, :comment_after_tag)
  end

  it "should punish Scenarios that have commented tags" do
    pending("this kind of test requires more definition around what elements comments 'belong' to")

    scenario_block = [
        '#@tag',
        "Scenario: Commented tag",
        "Given I am a step"
    ]
    test_scenario_rule(scenario_block, :commented_tag)
  end

  it "should not punish Scenarios that have a comment before any tags occur" do
    scenario_block = [
        "#comment",
        "@tag",
        "Scenario: I'm a scenario with a comment before a tag"
    ]
    test_no_scenario_rule(scenario_block, :comment_after_tag)
  end

  it "should punish implementation words Radio Button, not including button" do
    scenario_block = [
        "Scenario: I have a radio button",
        "When I am the first step",
        "Then I am the second step with a radio button"
    ]
    rule = CukeSniffer::CukeSnifferHelper.build_rule(:implementation_word, RULES[:implementation_word])
    run_rule_against_scenario(scenario_block, rule)
    @cli.features[0].scenarios[0].rules_hash.keys.include?("Implementation word used: radio button.").should be_true
    @cli.features[0].scenarios[0].rules_hash.keys.include?("Implementation word used: button.").should be_false
  end

  it "should not punish implementation word Button when Radio Button is used" do
    scenario_block = [
        "Scenario: I have a radio button",
        "When I am the first step",
        "Then I am the second step with a radio button"
    ]
    rule = CukeSniffer::CukeSnifferHelper.build_rule(:implementation_word, RULES[:implementation_word_button])
    run_rule_against_scenario(scenario_block, rule)
    @cli.features[0].scenarios[0].rules_hash.keys.include?("Implementation word used: button.").should be_false
  end

  it "should punish implementation word button" do
    scenario_block = [
        "Scenario: I have a button",
        "When I am the first step",
        "Then I am the second step with a button"
    ]
    rule = CukeSniffer::CukeSnifferHelper.build_rule(:implementation_word, RULES[:implementation_word_button])
    run_rule_against_scenario(scenario_block, rule)
    @cli.features[0].scenarios[0].rules_hash.keys.include?("Implementation word used: button.").should be_true
  end

  it 'should not punish a scenario that has two comments before any tags' do
    scenario_block = [
        '# I am a comment',
        '# I am another comment',
        '@tag1 @tag2',
        'Scenario: Test Scenario',
        'When I am the first step',
    ]
    test_no_scenario_rule(scenario_block, :comment_after_tag)
  end

end

describe "BackgroundRules" do
  def run_rule_against_background(background_block, rule)
    background = CukeSniffer::Scenario.new("location:1", background_block)
    build_file([], @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    delete_temp_files
    feature.background = background
    @cli.features = [feature]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
  end

  def test_background_rule(background_block, symbol, count = 1)
    rule = CukeSniffer::CukeSnifferHelper.build_rule(symbol, RULES[symbol])
    run_rule_against_background(background_block, rule)
    verify_rule(@cli.features.first.background, rule, count)
  end

  def test_no_background_rule(background_block, symbol)
    rule = CukeSniffer::CukeSnifferHelper.build_rule(symbol, RULES[symbol])
    run_rule_against_background(background_block, rule)
    verify_no_rule(@cli.features.first.background, rule)
  end

  before(:each) do
    @file_name = "my_feature.feature"
    @cli = CukeSniffer::CLI.new()
  end

  after(:all) do
    delete_temp_files
  end

  it "should not punish Backgrounds without a name" do
    background_block = [
        "Background:"
    ]
    test_no_background_rule(background_block, :no_description)
  end

  it "should punish Backgrounds with no steps" do
    background_block = [
        "Background: Empty Scenario"
    ]
    test_background_rule(background_block, :no_steps)
  end

  it "should punish Backgrounds with numbers in its name" do
    background_block = [
        "Background: Background with some digits 123"
    ]
    test_background_rule(background_block, :numbers_in_description)
  end

  it "should punish Backgrounds with long names" do
    background_description = ""
    RULES[:long_name][:max].times { background_description << "A" }
    background_block = [
        "Background: #{background_description}"
    ]
    test_background_rule(background_block, :long_name)
  end

  it "should punish Backgrounds with too many steps" do
    background_block = [
        "Background: Scenario with too many steps"
    ]
    (RULES[:too_many_steps][:max]+1).times { background_block << "And I have too many steps" }
    test_background_rule(background_block, :too_many_steps)
  end

  it "should not punish Backgrounds with steps that are out of order: Then/When" do
    background_block = [
        "Background: Scenario with out of order steps",
        "Then comes first",
        "When comes second"
    ]
    test_no_background_rule(background_block, :out_of_order_steps)
  end

  it "should not punish Backgrounds with steps that are out of order: Then/When/Given" do
    background_block = [
        "Background: Scenario with out of order steps",
        "Then comes first",
        "When comes second",
        "Given comes third"
    ]
    test_no_background_rule(background_block, :out_of_order_steps)
  end

  it "should not punish Backgrounds with steps that are out of order: Given/Then/And/When" do
    background_block = [
        "Background: Scenario with out of order steps",
        "Given comes first",
        "Then comes second",
        "And is ignored",
        "When comes third"
    ]
    rule = CukeSniffer::CukeSnifferHelper.build_rule(:out_of_order_steps, RULES[:out_of_order_steps])
    run_rule_against_background(background_block, rule)
    @cli.features.first.background.rules_hash.include?(rule.phrase).should be_false
  end

  it "should punish Backgrounds with And as its first step" do
    background_block = [
        "Background: Background with And as its first step",
        "And is not a valid first step",
    ]
    test_background_rule(background_block, :invalid_first_step)
  end

  it "should punish Backgrounds with But as its first step" do
    background_block = [
        "Background: Background with But as its first step",
        "But is not a valid first step",
        "When comes first"
    ]
    test_background_rule(background_block, :invalid_first_step)
  end

  it "should punish Backgrounds that use the * step" do
    background_block = [
        "Background: Background with *",
        "* is an awesome operator"
    ]
    test_background_rule(background_block, :asterisk_step)
  end

  it "should punish each step in a Background that uses *" do
    background_block = [
        "Background: Background with *",
        "Given I am first",
        "* is an awesome operator",
        "When I am second",
        "* is an awesome operator",
        "Then I am third"
    ]
    test_background_rule(background_block, :asterisk_step, 2)
  end

  it "should punish Backgrounds with commented steps" do
    feature_block = [
        'Feature:',
        "Background: Background with commented line",
        "#Given I am first",
        "When I am second",
        "Then I am third"
    ]
    @file_name = 'foo.feature'

    rule = CukeSniffer::CukeSnifferHelper.build_rule(:commented_step, RULES[:commented_step])
    build_file(feature_block, @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    delete_temp_files
    @cli.features = [feature]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    verify_rule(@cli.features.first.background, rule, 1)
  end

  it "should punish each step in a Background that is commented" do
    feature_block = [
        'Feature:',
        "Background: Background with commented line",
        "#Given I am first",
        "#When I am second",
        "#Then I am third",
        'Scenario: Just an extra scenario to make sure that comments are not lost in gherkin 2.x'
    ]
    @file_name = 'foo.feature'

    rule = CukeSniffer::CukeSnifferHelper.build_rule(:commented_step, RULES[:commented_step])
    build_file(feature_block, @file_name)
    feature = CukeSniffer::Feature.new(@file_name)
    delete_temp_files
    @cli.features = [feature]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    verify_rule(@cli.features.first.background, rule, 3)
  end

  it "should not punish Backgrounds with too many tags" do
    pending('this behavior is not really doable anymore. replace')

    background_block = []
    RULES[:too_many_tags][:max].times { |n| background_block << "@tag_#{n}" }
    background_block << "Background: Scenario with many tags"
    test_no_background_rule(background_block, :too_many_tags)
  end

  it "should punish Backgrounds that use implementation words(page/site/ect)" do
    background_block = [
        "Background: Background with implementation words",
        "Given I am on the login page",
        "When I log in to the site",
        "Then I am on the home page",
    ]
    rule = CukeSniffer::CukeSnifferHelper.build_rule(:implementation_word, RULES[:implementation_word])
    run_rule_against_background(background_block, rule)
    background= @cli.features.first.background

    background.rules_hash.include?("Implementation word used: page.").should be_true
    background.rules_hash.include?("Implementation word used: site.").should be_true
    background.rules_hash["Implementation word used: page."].should == 2
    background.rules_hash["Implementation word used: site."].should == 1
  end

  it "should punish Backgrounds with steps that use fixed Dates(01/01/0001)" do
    background_block = [
        "Background: Background with dates used",
        "Given Today is 11/12/2013",
    ]
    test_background_rule(background_block, :date_used)
  end

  it "should punish Backgrounds steps with only one word." do
    background_block = [
        "Background: Step with one word",
        "Given word",
    ]
    test_background_rule(background_block, :one_word_step)
  end

  it "should punish Backgrounds with multiple steps with only one word." do
    background_block = [
        "Background: Step with one word",
        "Given word",
        "When nope",
    ]
    test_background_rule(background_block, :one_word_step, 2)
  end

  it "should punish Background that use Given more than once." do
    background_block = [
        "Background: Multiple Givens",
        "Given I am doing setup",
        "Given I am doing more setup",
    ]
    test_background_rule(background_block, :multiple_given_when_then)
  end

  it "should punish Backgrounds that use When more than once." do
    background_block = [
        "Background: Multiple Givens",
        "When I am doing setup",
        "When I am doing more setup",
    ]
    test_background_rule(background_block, :multiple_given_when_then)
  end

  it "should punish Backgrounds that use Then more than once." do
    background_block = [
        "Background: Multiple Givens",
        "Then I am doing setup",
        "Then I am doing more setup",
    ]
    test_background_rule(background_block, :multiple_given_when_then)
  end

  it "should punish Backgrounds that have tags" do
    pending('this behavior is not really doable anymore. replace')

    background_block = [
        "@tag",
        "Background: I am a background",
        "Given I am a step",
    ]
    test_background_rule(background_block, :background_with_tag)
  end

end
