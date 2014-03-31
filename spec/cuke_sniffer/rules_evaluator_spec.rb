require 'spec_helper'
require 'cuke_sniffer/rules_evaluator'

describe CukeSniffer::RulesEvaluator do

  def build_rule
    rule = CukeSniffer::Rule.new()
    rule.phrase = "A rule"
    rule.targets = []
    rule.enabled = true
    rule.score = 10
    rule.reason = lambda { |object, rule| true}
    rule
  end

  before(:each) do
    @cli = CukeSniffer::CLI.new()
    @file_name = "my_feature.feature"
  end

  after(:each) do
    delete_temp_files
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
    expect {CukeSniffer::RulesEvaluator.new(nil, [CukeSniffer::Rule.new()])}.to raise_error("A CLI must be provided for evaluation.")
  end

  it "should throw an exception when Rules are nil" do
    expect {CukeSniffer::RulesEvaluator.new(CukeSniffer::CLI.new(), nil) }.to raise_error("Rules must be provided for evaluation.")
  end

  it "should throw an exception when Rules are empty" do
    expect {CukeSniffer::RulesEvaluator.new(CukeSniffer::CLI.new(), [])}.to raise_error("Rules must be provided for evaluation.")
  end

  it "should throw an exception when a Rule has nil targets" do
    rule = CukeSniffer::Rule.new()
    rule.phrase = "Exceptions are fun!"
    rule.targets = []

    step_definition_block = [
        "Given /^ stuff $/ do",
        "",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location.rb:1", step_definition_block)
    @cli.step_definitions = [step_definition]
    expect {CukeSniffer::RulesEvaluator.new(@cli, [rule])}.to raise_error("No targets for rule: #{rule.phrase}")
  end

  it "should throw an exception when a Rule has nil targets" do
    rule = CukeSniffer::Rule.new()
    rule.phrase = "Exceptions are fun!"
    rule.targets = nil

    step_definition_block = [
        "Given /^ stuff $/ do",
        "",
        "end"
    ]
    step_definition = CukeSniffer::StepDefinition.new("location.rb:1", step_definition_block)
    @cli.step_definitions = [step_definition]
    expect {CukeSniffer::RulesEvaluator.new(@cli, [rule])}.to raise_exception("No targets for rule: #{rule.phrase}")
  end

  it "should judge all features for rules that are enabled and targeted at Features" do
    rule = build_rule
    rule.targets = ["Feature"]

    build_file(["Feature: Testing"], @file_name)
    @cli.features = [CukeSniffer::Feature.new(@file_name)]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.features.first, rule)
  end

  it "should not judge any features for a rule that is disabled" do
    rule = build_rule
    rule.targets = ["Feature"]
    rule.enabled = false
    rule.score = 1000

    feature_block = [
        "Feature: Testing"
    ]
    build_file(feature_block, @file_name)
    @cli.features = [CukeSniffer::Feature.new(@file_name)]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])

    judged_feature = @cli.features.first
    judged_feature.rules_hash[rule.phrase].should == nil
    judged_feature.score.should <= rule.score
  end

  it "should judge all scenarios in a feature for rules that are enabled and targeted at Scenarios" do
    rule = build_rule
    rule.targets = ["Scenario"]

    feature_block = [
        "Feature: Testing",
        "Scenario: Testing Again"
    ]
    build_file(feature_block, @file_name)
    @cli.features = [CukeSniffer::Feature.new(@file_name)]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.features.first.scenarios.first, rule)
  end

  it "should judge any scenarios in a feature for rules that are disabled" do
    rule = build_rule
    rule.targets = ["Scenario"]
    rule.enabled = false
    rule.score = 1000

    feature_block = [
        "Feature: Testing",
        "Scenario: Testing Again"
    ]
    build_file(feature_block, @file_name)
    @cli.features = [CukeSniffer::Feature.new(@file_name)]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    judged_scenario = @cli.features.first.scenarios.first
    judged_scenario.rules_hash[rule.phrase].should == nil
    judged_scenario.score.should <= rule.score
  end

  it "should include the score of all scenarios in a feature in its total score" do
    rule = build_rule
    rule.targets = ["Scenario"]

    feature_block = [
        "Feature: Testing",
        "Scenario: Testing Again",
        "Scenario: Testing Again"
    ]
    build_file(feature_block, @file_name)
    @cli.features = [CukeSniffer::Feature.new(@file_name)]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    @cli.features.first.total_score.should == rule.score * 2
  end

  it "should judge a background in a feature for rules that are enabled and targeted at Backgrounds" do
    rule = build_rule
    rule.targets = ["Background"]

    feature_block = [
        "Feature: Testing",
        "Background: Testing Again"
    ]
    build_file(feature_block, @file_name)
    @cli.features = [CukeSniffer::Feature.new(@file_name)]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.features.first.background, rule)
  end

  it "should judge all step_definitions for rules that are enabled and targeted at StepDefinition" do
    rule = build_rule
    rule.targets = ["StepDefinition"]

    step_definition_block = [
        "When /^the second number is 1$/ do",
        "@second_number = 1",
        "end"
    ]
    @cli.step_definitions = [CukeSniffer::StepDefinition.new("location:1", step_definition_block)]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.step_definitions.first, rule)
  end

  it "should judge all hooks for rules that are enabled and targeted at Hook" do
    rule = build_rule
    rule.targets = ["Hook"]

    hook_block = [
        "AfterConfiguration do",
        "1+1",
        "end"
    ]
    @cli.hooks = [CukeSniffer::Hook.new("location:1", hook_block)]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.hooks.first, rule)
  end

  it "should allow the passing of custom phrases for storing rules" do
    rule = build_rule
    rule.targets = ["Background"]
    rule.reason = lambda { |object, rule| object.store_rule(rule, "my_new_phrase")
                    false
                  }
    @file_name = "my_feature.feature"
    feature_block = [
        "Feature: Testing",
        "Background: Testing Again"
    ]
    build_file(feature_block, @file_name)
    @cli.features = [CukeSniffer::Feature.new(@file_name)]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    @cli.features.first.background.rules_hash["my_new_phrase"].should == 1
  end

  it "should update a phrase that contains {class} with the type that is being evaluated" do
    rule = build_rule
    rule.phrase = "my class is {class}."
    rule.targets = ["Background"]
    feature_block = [
        "Feature: Testing",
        "Background: Testing Again"
    ]
    build_file(feature_block, @file_name)
    @cli.features = [CukeSniffer::Feature.new(@file_name)]
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    @cli.features.first.background.rules_hash["my class is Background."].should == 1
  end

end