require 'spec_helper'

describe CukeSniffer::RulesEvaluator do

  before(:each) do
    @cli = CukeSniffer::CLI.new()
  end

  it "should take an instance of CLI and Rules to store" do
    rule = CukeSniffer::Rule.new()
    rule.phrase = "testing"
    rule.targets = ["Scenario"]
    rules = [rule]

    judge = CukeSniffer::RulesEvaluator.new(@cli, rules)
    judge.rules.should == rules
  end

  it "should throw an exception when no CLI is passed in" do
    begin
      CukeSniffer::RulesEvaluator.new(nil, [CukeSniffer::Rule.new()])
    rescue Exception => e
      e.message.should == "A CLI must be provided for evaluation."
    end
  end

  it "should throw an exception when Rules are nil" do
    begin
      CukeSniffer::RulesEvaluator.new(CukeSniffer::CLI.new(), nil)
    rescue Exception => e
      e.message.should == "Rules must be provided for evaluation."
    end
  end

  it "should throw an exception when Rules are empty" do
    begin
      CukeSniffer::RulesEvaluator.new(CukeSniffer::CLI.new(), [])
      fail "no exception thrown from Judge"
    rescue Exception => e
      e.message.should == "Rules must be provided for evaluation."
    end
  end

  it "should throw an exception when a Rule has nil targets" do
    begin
      rule = CukeSniffer::Rule.new()
      rule.phrase = "Exceptions are fun!"
      rule.targets = []
      step_definition = CukeSniffer::StepDefinition.new("location.rb:1", ["Given /^ stuff $/ do", "", "end"])
      @cli.step_definitions = [step_definition]
      CukeSniffer::RulesEvaluator.new(@cli, [rule])
      fail "no exception thrown from Judge"
    rescue Exception => e
      e.message.should == "No targets for rule: #{rule.phrase}"
    end
  end

  it "should throw an exception when a Rule has nil targets" do
    begin
      rule = CukeSniffer::Rule.new()
      rule.phrase = "Exceptions are fun!"
      rule.targets = nil
      step_definition = CukeSniffer::StepDefinition.new("location.rb:1", ["Given /^ stuff $/ do", "", "end"])
      @cli.step_definitions = [step_definition]
      CukeSniffer::RulesEvaluator.new(@cli, [rule])
      fail "no exception thrown from Judge"
    rescue Exception => e
      e.message.should == "No targets for rule: #{rule.phrase}"
    end
  end

  it "should judge all features for rules that are enabled and targeted at Features" do
    rule = build_rule

    rule.targets = ["Feature"]

    feature_file_name = "my_feature.feature"
    build_file(["Feature: Testing"], feature_file_name)
    @cli.features = [CukeSniffer::Feature.new(feature_file_name)]
    File.delete(feature_file_name)

    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    verify_rule(@cli.features[0], rule)
  end

  it "should not judge any features for a rule that is disabled" do
    rule = build_rule
    rule.targets = ["Feature"]
    rule.enabled = false
    rule.score = 1000

    feature_file_name = "my_feature.feature"
    build_file(["Feature: Testing"], feature_file_name)
    @cli.features = [CukeSniffer::Feature.new(feature_file_name)]
    File.delete(feature_file_name)

    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    judged_feature = @cli.features[0]
    judged_feature.rules_hash[rule.phrase].should == nil
    judged_feature.score.should <= rule.score
  end

  it "should judge all scenarios in a feature for rules that are enabled and targeted at Scenarios" do
    rule = build_rule
    rule.targets = ["Scenario"]

    feature_file_name = "my_feature.feature"
    build_file(["Feature: Testing", "Scenario: Testing Again"], feature_file_name)
    @cli.features = [CukeSniffer::Feature.new(feature_file_name)]
    File.delete(feature_file_name)

    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    verify_rule(@cli.features[0].scenarios[0], rule)
  end

  it "should judge any scenarios in a feature for rules that are disabled" do
    rule = build_rule
    rule.targets = ["Scenario"]
    rule.enabled = false
    rule.score = 1000

    feature_file_name = "my_feature.feature"
    build_file(["Feature: Testing", "Scenario: Testing Again"], feature_file_name)
    @cli.features = [CukeSniffer::Feature.new(feature_file_name)]
    File.delete(feature_file_name)

    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    judged_scenario = @cli.features[0].scenarios[0]
    judged_scenario.rules_hash[rule.phrase].should == nil
    judged_scenario.score.should <= rule.score
  end

  it "should include the score of all scenarios in a feature in its total score" do
    rule = build_rule
    rule.targets = ["Scenario"]

    feature_file_name = "my_feature.feature"
    build_file(["Feature: Testing", "Scenario: Testing Again", "Scenario: Testing Again"], feature_file_name)
    @cli.features = [CukeSniffer::Feature.new(feature_file_name)]
    File.delete(feature_file_name)

    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    @cli.features[0].total_score.should == rule.score * 2

  end

  it "should judge a background in a feature for rules that are enabled and targeted at Backgrounds" do
    rule = build_rule
    rule.targets = ["Background"]

    feature_file_name = "my_feature.feature"
    build_file(["Feature: Testing", "Background: Testing Again"], feature_file_name)
    @cli.features = [CukeSniffer::Feature.new(feature_file_name)]
    File.delete(feature_file_name)

    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    verify_rule(@cli.features[0].background, rule)
  end

  it "should judge all step_definitions for rules that are enabled and targeted at StepDefinition" do
    rule = build_rule
    rule.targets = ["StepDefinition"]

    raw_code = ["When /^the second number is 1$/ do",
                "@second_number = 1",
                "end"]

    @cli.step_definitions = [CukeSniffer::StepDefinition.new("location:1", raw_code)]

    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    verify_rule(@cli.step_definitions[0], rule)
  end

  it "should judge all hooks for rules that are enabled and targeted at Hook" do
    rule = build_rule
    rule.targets = ["Hook"]

    raw_code = ["AfterConfiguration do",
                "1+1",
                "end"]

    @cli.hooks = [CukeSniffer::Hook.new("location:1", raw_code)]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    verify_rule(@cli.hooks[0], rule)
  end

  it "should allow the passing of custom phrases for storing rules" do
    rule = build_rule
    rule.targets = ["Background"]
    rule.reason = " store_rule(object, rule, \"my_new_phrase\")
                    false
                  "
    feature_file_name = "my_feature.feature"
    build_file(["Feature: Testing", "Background: Testing Again"], feature_file_name)
    @cli.features = [CukeSniffer::Feature.new(feature_file_name)]
    File.delete(feature_file_name)

    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    @cli.features[0].background.rules_hash["my_new_phrase"].should == 1
  end

  it "should update a phrase that contains {class} with the type that is being evaluated" do
    rule = build_rule
    rule.phrase = "my class is {class}."
    rule.targets = ["Background"]
    feature_file_name = "my_feature.feature"
    build_file(["Feature: Testing", "Background: Testing Again"], feature_file_name)
    @cli.features = [CukeSniffer::Feature.new(feature_file_name)]
    File.delete(feature_file_name)

    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    @cli.features[0].background.rules_hash["my class is Background."].should == 1
  end

  def build_rule
    rule = CukeSniffer::Rule.new()
    rule.phrase = "A rule"
    rule.targets = []
    rule.enabled = true
    rule.score = 10
    rule.reason = "true"
    rule
  end

end