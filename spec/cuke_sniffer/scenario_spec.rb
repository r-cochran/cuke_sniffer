require 'spec_helper'

include CukeSniffer::RuleConfig

describe CukeSniffer::Scenario do

  it "should retain the passed location, name, and the steps of the scenario step after initialization" do
    scenario = [
        "Scenario: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    location = "path/path/path/my_feature.feature:1"
    step_definition = CukeSniffer::Scenario.new(location, scenario)
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
    step_definition = CukeSniffer::Scenario.new(location, scenario)
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
    step_definition = CukeSniffer::Scenario.new(location, scenario)
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
        "#comment before scenario",
        "Scenario: Test Scenario",
        "Given I am making a scenario",
        "When I make the scenario",
        "Then the scenario is made",
    ]
    location = "path/path/path/my_feature.feature:1"
    step_definition = CukeSniffer::Scenario.new(location, scenario)
    step_definition.location.should == location
    step_definition.name.should == "Test Scenario"
    step_definition.tags.should == ["@tag1", "@tag2", "@tag3", "#comment before scenario"]
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
    scenario = CukeSniffer::Scenario.new(location, scenario_block)
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

  it "should evaluate the scenario and the score should be greater than 0" do
    scenario_block = [
        "Scenario: Test Scenario with empty scenario rule firing",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.score.should > 0
  end

  it "should evaluate the scenario and then update a list of rules/occurrences" do
    scenario_block = [
        "Scenario: Test Scenario to fire empty scenario rule",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
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
    scenario = CukeSniffer::Scenario.new("location:1", scenario)
    scenario.name.should == "Test My Multi-line Scenario"
  end

  it "should only include examples in the examples table and not white space" do
    raw_code = [
        "Scenario Outline: Examples table should not keep white space or comments",
        "Examples:",
        "|var_name|",
        "|one|",
        "#|two|",
        "",
        "|three|",
        ""
    ]

    scenario = CukeSniffer::Scenario.new("location:1", raw_code)
    scenario.examples_table.should == %w(|var_name| |one| #|two| |three|)
  end

  it "should only include steps and not white space" do
    raw_code = [
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

    scenario = CukeSniffer::Scenario.new("location:1", raw_code)
    scenario.steps.should == ["Given I am a thing", "And I am also a thing","#      When I skip a line", "Then I should have an interesting scenario"]
  end

  it "should capture a scenario even if it commented out" do
    raw_code = [
        "# Scenario: I am a commented Scenario",
        "# Given I am commented",
        "When I am commented",
        "#Then we are all commented"
    ]

    scenario = CukeSniffer::Scenario.new("location:1", raw_code)
    scenario.name.should == "I am a commented Scenario"
  end

  it "should capture inline tables and associate them with the step using the table" do
    raw_code = [
        "Scenario: It has an inline table",
        "Given the in line table is here",
        "|one|two|three|",
        "|1|2|3|"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", raw_code)
    scenario.inline_tables["Given the in line table is here"].should == %w(|one|two|three| |1|2|3|)
  end

  it "should not clip steps after an inline table" do
    raw_code = [
        "Scenario: It has an inline table",
        "Given the in line table is here",
        "|one|two|three|",
        "|1|2|3|",
        "And I am still here"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", raw_code)
    scenario.steps.should == ["Given the in line table is here", "And I am still here"]
  end

  it "should not clip steps after multiple inline table" do
    raw_code = [
        "Scenario: It has an inline table",
        "Given the in line table is here",
        "|one|two|three|",
        "|1|2|3|",
        "And I am still here",
        "| are you sure |",
        "| really sure |",
        "Then I am at the end"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", raw_code)
    scenario.steps.should == ["Given the in line table is here", "And I am still here", "Then I am at the end"]
  end

  it "should determine if it is above the scenario threshold" do
    raw_code = [
        "Scenario: Above scenario threshold",
        "#Given I am a good scenario",
        "#When I do a behavior inducing action",
        "#Then that action is verified"
    ]

    start_threshold = CukeSniffer::Constants::THRESHOLDS["Scenario"]
    CukeSniffer::Constants::THRESHOLDS["Scenario"] = 2
    scenario = CukeSniffer::Scenario.new("location:1", raw_code)
    scenario.good?.should == false
    CukeSniffer::Constants::THRESHOLDS["Scenario"] = start_threshold
  end

  it "should determine if it is below the scenario threshold" do
    raw_code = [
        "Scenario: Below scenario threshold",
        "Given I am a good scenario",
        "When I do a behavior inducing action",
        "Then that action is verified"
    ]

    start_threshold = CukeSniffer::Constants::THRESHOLDS["Scenario"]
    CukeSniffer::Constants::THRESHOLDS["Scenario"] = 2
    scenario = CukeSniffer::Scenario.new("location:1", raw_code)
    scenario.good?.should == true
    CukeSniffer::Constants::THRESHOLDS["Scenario"] = start_threshold
  end

  it "should determine the percentage of problems compared to the scenario threshold" do
    raw_code = [
        "Scenario: Above scenario threshold",
        "#Given I am a good scenario",
        "#When I do a behavior inducing action",
        "#Then that action is verified"
    ]

    start_threshold = CukeSniffer::Constants::THRESHOLDS["Scenario"]
    CukeSniffer::Constants::THRESHOLDS["Scenario"] = 2
    scenario = CukeSniffer::Scenario.new("location:1", raw_code)
    scenario.score = 3
    scenario.problem_percentage.should == (3.0/2.0).to_f
    CukeSniffer::Constants::THRESHOLDS["Scenario"] = start_threshold
  end

  it "should not have a rule ran against a commented step besides the normal rule" do
    raw_code = [
        "Scenario: Above scenario threshold",
        "Given blarg",
        "#* button button button",
        "When I do a behavior inducing action",
        "Then that action is verified"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", raw_code)
    comment_rule = CukeSniffer::RuleConfig::RULES[:commented_step]
    asterisk_rule = CukeSniffer::RuleConfig::RULES[:asterisk_step]
    scenario.rules_hash.keys.include?(comment_rule[:phrase]).should be_true
    scenario.rules_hash.keys.include?(asterisk_rule[:phrase]).should be_false
  end

end

describe "ScenarioRules" do

  def validate_rule(scenario, rule)
    phrase = rule[:phrase].gsub(/{.*}/, "Scenario")

    scenario.rules_hash.include?(phrase).should be_true
    scenario.rules_hash[phrase].should > 0
    scenario.score.should >= rule[:score]
  end

  #TODO Extract and unify
  def validate_no_rule(scenario, rule)
    phrase = rule[:phrase].gsub(/{.*}/, "Scenario")

    scenario.rules_hash.include?(phrase).should be_false
  end

  it "should punish Scenarios without a name" do
    scenario_block = %w(Scenario:)
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:no_description])
  end

  it "should punish Scenarios with no steps" do
    scenario_block = [
        "Scenario: Empty Scenario",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:no_steps])
  end

  it "should punish Scenarios with numbers in its name" do
    scenario_block = [
        "Scenario: Scenario with some digits 123"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:numbers_in_description])
  end

  it "should punish Scenarios with long names" do
    rule = RULES[:long_name]
    scenario_description = ""
    rule[:max].times{scenario_description << "A"}
    scenario_block = [
        "Scenario: #{scenario_description}"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, rule)
  end

  it "should punish Scenarios with too many steps" do
    rule = RULES[:too_many_steps]
    scenario_block = [
        "Scenario: Scenario with too many steps"
    ]
    rule[:max].times {scenario_block << "And I have too many steps"}
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)

    validate_rule(scenario, rule)
  end

  it "should punish Scenarios with steps that are out of order: Then/When" do
    scenario_block = [
        "Scenario: Scenario with out of order steps",
        "Then comes first",
        "When comes second"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)

    validate_rule(scenario, RULES[:out_of_order_steps])
  end

  it "should punish Scenarios with steps that are out of order: Then/When/Given" do
    scenario_block = [
        "Scenario: Scenario with out of order steps",
        "Then comes first",
        "When comes second",
        "Given comes third"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)

    validate_rule(scenario, RULES[:out_of_order_steps])
  end

  it "should punish Scenarios with steps that are out of order: Given/Then/And/When" do
    scenario_block = [
        "Scenario: Scenario with out of order steps",
        "Given comes first",
        "Then comes second",
        "And is ignored",
        "When comes third"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:out_of_order_steps])
  end

  it "should punish Scenarios with And as its first step" do
    scenario_block = [
        "Scenario: Scenario with And as its first step",
        "And is not a valid first step",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:invalid_first_step])
  end

  it "should punish Scenarios with But as its first step" do
    scenario_block = [
        "Scenario: Scenario with But as its first step",
        "But is not a valid first step",
        "When comes first"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:invalid_first_step])
  end

  it "should punish Scenarios that use the * step" do
    scenario_block = [
        "Scenario: Scenario with *",
        "* is an awesome operator"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:asterisk_step])
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
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.score.should >= 4
    scenario.rules_hash[RULES[:asterisk_step][:phrase]].should == 2
  end

  it "should punish Scenarios with commented steps" do
    scenario_block = [
        "Scenario: Scenario with commented line",
        "#Given I am first",
        "When I am second",
        "Then I am third"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:commented_step])
  end

  it "should punish each step in a Scenario that is commented" do
    scenario_block = [
        "Scenario: Scenario with commented line",
        "#Given I am first",
        "#When I am second",
        "#Then I am third"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.rules_hash[RULES[:commented_step][:phrase]].should == 3
  end

  it "should punish Scenario Outlines with commented examples" do
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
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:commented_example])
  end

  it "should punish each commented example in a Scenario Outline" do
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
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?(RULES[:commented_example][:phrase]).should be_true
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
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:no_examples])
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
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:one_example])
  end

  it "should punish Scenario Outlines without the Examples table" do
    scenario_block = [
        "Scenario Outline: Scenario with no examples table",
        "Given I am first",
        "When I am second",
        "Then I am third",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:no_examples_table])
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
    rule[:max].times{|n| scenario_block << "|#{n}|"}
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:too_many_examples])
  end

  it "should punish Scenarios with too many tags" do
    rule = RULES[:too_many_tags]
    scenario_block = []
    rule[:max].times{|n| scenario_block << "@tag_#{n}"}
    scenario_block << "Scenario: Scenario with many tags"

    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, rule)
  end

  it "should punish Scenarios that use implementation words(page/site/ect)" do
    scenario_block = [
        "Scenario: Scenario with implementation words",
        "Given I am on the login page",
        "When I log in to the site",
        "Then I am on the home page",
    ]

    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.rules_hash.include?("Implementation word used: page.").should be_true
    scenario.rules_hash.include?("Implementation word used: site.").should be_true
    scenario.rules_hash["Implementation word used: page."].should == 2
    scenario.rules_hash["Implementation word used: site."].should == 1
  end

  it "should punish Scenarios with steps that use fixed Dates(01/01/0001)" do
    scenario_block = [
        "Scenario: Scenario with dates used",
        "Given Today is 11/12/2013",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:date_used])
  end

  it "should punish Scenario steps with only one word." do
    scenario_block = [
        "Scenario: Step with one word",
        "Given word",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:one_word_step])
  end

  it "should punish Scenarios with multiple steps with only one word." do
    scenario_block = [
        "Scenario: Step with one word",
        "Given word",
        "When nope",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    scenario.rules_hash[RULES[:one_word_step][:phrase]].should == 2
  end

  it "should punish Scenarios that use Given more than once." do
    scenario_block = [
        "Scenario: Multiple Givens",
        "Given I am doing setup",
        "Given I am doing more setup",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:multiple_given_when_then])
  end

  it "should punish Scenarios that use When more than once." do
    scenario_block = [
        "Scenario: Multiple Givens",
        "When I am doing setup",
        "When I am doing more setup",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:multiple_given_when_then])
  end

  it "should punish Scenarios that use Then more than once." do
    scenario_block = [
        "Scenario: Multiple Givens",
        "Then I am doing setup",
        "Then I am doing more setup",
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:multiple_given_when_then])
  end

  it "should punish Scenarios that have commas in its description" do
    scenario_block = [
        "Scenario: Scenario with a comma, in its description"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:commas_in_description])
  end

  it "should punish Scenarios that have a comment on a line after a tag" do
    scenario_block = [
        "@tag",
        "#comment",
        "     #comment with spaces",
        "Scenario: Comment after Tag",
        "Given I am a step"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:comment_after_tag])
  end

  it "should not punish Scenarios that have a tag with a hash in it" do
    scenario_block = [
        "@tag",
        "@#comment",
        "Scenario: Comment after Tag",
        "Given I am a step"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_no_rule(scenario, RULES[:comment_after_tag])
  end

  it "should punish Scenarios that have commented tags" do
    scenario_block = [
        "\#tag",
        "Scenario: Commented tag",
        "Given I am a step"
    ]
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_rule(scenario, RULES[:commented_tag])
  end
end

describe "BackgroundRules" do

  def validate_rule(scenario, rule)
    phrase = rule[:phrase].gsub(/{.*}/, "Background")

    scenario.rules_hash.include?(phrase).should be_true
    scenario.rules_hash[phrase].should > 0
    scenario.score.should >= rule[:score]
  end

  def validate_no_rule(scenario, rule)
    phrase = rule[:phrase].gsub(/{.*}/, "Background")

    scenario.rules_hash.include?(phrase).should be_false
  end

  it "should not punish Backgrounds without a name" do
    scenario_block = %w(Background:)
    scenario = CukeSniffer::Scenario.new("location:1", scenario_block)
    validate_no_rule(scenario, RULES[:no_description])
  end

  it "should punish Backgrounds with no steps" do
    background_block = [
        "Background: Empty Scenario",
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_rule(background, RULES[:no_steps])
  end

  it "should punish Backgrounds with numbers in its name" do
    background_block = [
        "Background: Background with some digits 123"
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_rule(background, RULES[:numbers_in_description])
  end

  it "should punish Backgrounds with long names" do
    rule = RULES[:long_name]
    background_description = ""
    rule[:max].times{background_description << "A"}
    background_block = [
        "Background: #{background_description}"
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_rule(background, rule)
  end

  it "should punish Backgrounds with too many steps" do
    rule = RULES[:too_many_steps]
    background_block = [
        "Background: Scenario with too many steps"
    ]
    rule[:max].times {background_block << "And I have too many steps"}
    background = CukeSniffer::Scenario.new("location:1", background_block)

    validate_rule(background, rule)
  end

  it "should not punish Backgrounds with steps that are out of order: Then/When" do
    background_block = [
        "Background: Scenario with out of order steps",
        "Then comes first",
        "When comes second"
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)

    validate_no_rule(background, RULES[:out_of_order_steps])
  end

  it "should not punish Backgrounds with steps that are out of order: Then/When/Given" do
    background_block = [
        "Background: Scenario with out of order steps",
        "Then comes first",
        "When comes second",
        "Given comes third"
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)

    validate_no_rule(background, RULES[:out_of_order_steps])
  end

  it "should not punish Backgrounds with steps that are out of order: Given/Then/And/When" do
    background_block = [
        "Background: Scenario with out of order steps",
        "Given comes first",
        "Then comes second",
        "And is ignored",
        "When comes third"
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_no_rule(background, RULES[:out_of_order_steps])
  end

  it "should punish Backgrounds with And as its first step" do
    background_block = [
        "Background: Background with And as its first step",
        "And is not a valid first step",
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_rule(background, RULES[:invalid_first_step])
  end

  it "should punish Backgrounds with But as its first step" do
    background_block = [
        "Background: Background with But as its first step",
        "But is not a valid first step",
        "When comes first"
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_rule(background, RULES[:invalid_first_step])
  end

  it "should punish Backgrounds that use the * step" do
    background_block = [
        "Background: Background with *",
        "* is an awesome operator"
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_rule(background, RULES[:asterisk_step])
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
    background = CukeSniffer::Scenario.new("location:1", background_block)
    background.score.should >= 4
    background.rules_hash[RULES[:asterisk_step][:phrase]].should == 2
  end

  it "should punish Backgrounds with commented steps" do
    background_block = [
        "Background: Scenario with commented line",
        "#Given I am first",
        "When I am second",
        "Then I am third"
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_rule(background, RULES[:commented_step])
  end

  it "should punish each step in a Background that is commented" do
    background_block = [
        "Background: Background with commented line",
        "#Given I am first",
        "#When I am second",
        "#Then I am third"
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    background.rules_hash[RULES[:commented_step][:phrase]].should == 3
  end

  it "should not punish Backgrounds with too many tags" do
    rule = RULES[:too_many_tags]
    background_block = []
    rule[:max].times{|n| background_block << "@tag_#{n}"}
    background_block << "Background: Scenario with many tags"

    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_no_rule(background, rule)
  end

  it "should punish Backgrounds that use implementation words(page/site/ect)" do
    background_block = [
        "Background: Background with implementation words",
        "Given I am on the login page",
        "When I log in to the site",
        "Then I am on the home page",
    ]

    background = CukeSniffer::Scenario.new("location:1", background_block)
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
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_rule(background, RULES[:date_used])
  end

  it "should punish Backgrounds steps with only one word." do
    background_block = [
        "Background: Step with one word",
        "Given word",
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_rule(background, RULES[:one_word_step])
  end

  it "should punish Backgrounds with multiple steps with only one word." do
    background_block = [
        "Background: Step with one word",
        "Given word",
        "When nope",
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    background.rules_hash[RULES[:one_word_step][:phrase]].should == 2
  end

  it "should punish Background that use Given more than once." do
    background_block = [
        "Background: Multiple Givens",
        "Given I am doing setup",
        "Given I am doing more setup",
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_rule(background, RULES[:multiple_given_when_then])
  end

  it "should punish Backgrounds that use When more than once." do
    background_block = [
        "Background: Multiple Givens",
        "When I am doing setup",
        "When I am doing more setup",
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_rule(background, RULES[:multiple_given_when_then])
  end

  it "should punish Backgrounds that use Then more than once." do
    background_block = [
        "Background: Multiple Givens",
        "Then I am doing setup",
        "Then I am doing more setup",
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_rule(background, RULES[:multiple_given_when_then])
  end

  it "should punish Backgrounds that have tags" do
    background_block = [
        "@tag",
        "Background: I am a background",
        "Given I am a step",
    ]
    background = CukeSniffer::Scenario.new("location:1", background_block)
    validate_rule(background, RULES[:background_with_tag])
  end
end
