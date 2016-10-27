require 'spec_helper'

describe CukeSniffer do

  describe "Handling Project" do
    it "should determine if it is above the project threshold" do
      cuke_sniffer = CukeSniffer::CLI.new()
      start_threshold = CukeSniffer::Constants::THRESHOLDS["Project"]
      CukeSniffer::Constants::THRESHOLDS["Project"] = 2
      cuke_sniffer.summary[:total_score] = 3
      cuke_sniffer.good?.should == false
      CukeSniffer::Constants::THRESHOLDS["Project"] = start_threshold
    end

    it "should tabulate a total score for the project when summarizing the data." do
      cuke_sniffer = CukeSniffer::CLI.new()

      features_score = 300
      @file_name = "my_feature.feature"
      feature_block = [
          "Feature:"
      ]
      build_file(feature_block, @file_name)
      feature = CukeSniffer::Feature.new(@file_name)
      feature.score = features_score

      step_definition_block = [
          "Given /^stuff$/ do",
          "puts 'stuff'",
          "end"
      ]
      step_definition = CukeSniffer::StepDefinition.new("location.rb:1", step_definition_block)
      step_definitions_score = 299
      step_definition.score = step_definitions_score

      hook_block = [
          "Before do",
          "end"
      ]
      hook = CukeSniffer::Hook.new("location.rb:1", hook_block)
      hooks_score = 23
      hook.score = hooks_score

      cuke_sniffer.features = [feature]
      cuke_sniffer.scenarios = []
      cuke_sniffer.step_definitions = [step_definition]
      cuke_sniffer.hooks = [hook]

      cuke_sniffer.assess_score
      cuke_sniffer.summary[:total_score].should == features_score + step_definitions_score + hooks_score
    end

    it "should not catalog step definitions when the flag is sent to skip that step is true and keep track that nothing was cataloged" do
      feature_block = [
          "Feature: My feature that will not be cataloged",
          "",
          "Scenario: A scenario that will not be cataloged",
          "Give my step",
          "When my step",
          "Then my step"
      ]
      feature_file_name = "my_feature.feature"
      build_file(feature_block, feature_file_name)

      step_definition_block = [
          "Given /^my step$/ do",
          "end"
      ]
      step_definition_file = "step_def.rb"
      build_file(step_definition_block, step_definition_file)


      cuke_sniffer = CukeSniffer::CLI.new(
          {
              :features_location => feature_file_name,
              :step_definitions_location => step_definition_file,
              :no_catalog => true
          }
      )

      cuke_sniffer.step_definitions.first.calls.should be_empty
      cuke_sniffer.cataloged?.should be_false

      File.delete(feature_file_name)
      File.delete(step_definition_file)
    end

    it "should catalog step definitions when the flag is not sent to skip is false that step and keep track that step definitions were cataloged" do
      feature_block = [
          "Feature: My feature that will not be cataloged",
          "",
          "Scenario: A scenario that will not be cataloged",
          "Give my step",
          "When my step",
          "Then my step"
      ]
      feature_file_name = "my_feature.feature"
      build_file(feature_block, feature_file_name)

      step_definition_block = [
          "Given /^my step$/ do",
          "end"
      ]
      step_definition_file = "step_def.rb"
      build_file(step_definition_block, step_definition_file)


      cuke_sniffer = CukeSniffer::CLI.new(
          {
              :features_location => feature_file_name,
              :step_definitions_location => step_definition_file,
              :no_catalog => false
          }
      )

      cuke_sniffer.step_definitions.first.calls.should_not be_empty
      cuke_sniffer.cataloged?.should be_true

      File.delete(feature_file_name)
      File.delete(step_definition_file)
    end

    it "should catalog step definitions when the flag is not sent to skip that step and keep track that step definitions were cataloged" do
      feature_block = [
          "Feature: My feature that will not be cataloged",
          "",
          "Scenario: A scenario that will not be cataloged",
          "Give my step",
          "When my step",
          "Then my step"
      ]
      feature_file_name = "my_feature.feature"
      build_file(feature_block, feature_file_name)

      step_definition_block = [
          "Given /^my step$/ do",
          "end"
      ]
      step_definition_file = "step_def.rb"
      build_file(step_definition_block, step_definition_file)


      cuke_sniffer = CukeSniffer::CLI.new(
          {
              :features_location => feature_file_name,
              :step_definitions_location => step_definition_file,
          }
      )

      cuke_sniffer.step_definitions.first.calls.should_not be_empty
      cuke_sniffer.cataloged?.should be_true

      File.delete(feature_file_name)
      File.delete(step_definition_file)
    end

  end

  describe "Handling Features" do

    before(:each) do
      @file_name = "my_feature.feature"
    end

    after(:each) do
      delete_temp_files
    end

    it "should use the passed locations for features to store create features" do
      feature_block = ["Feature: I am the only feature."]
      build_file(feature_block, @file_name)
      cuke_sniffer = CukeSniffer::CLI.new({:features_location => @file_name})
      fail "features were not initialized" if cuke_sniffer.features == []
    end

    it "should be able to utilize a single feature file for parsing" do
      feature_block = ["Feature: I am the only feature."]
      build_file(feature_block, @file_name)
      cuke_sniffer = CukeSniffer::CLI.new({:features_location => @file_name})
      actual_features = remove_rules(cuke_sniffer.features)
      actual_features.should == [CukeSniffer::Feature.new(@file_name)]
    end

    it "should be able to handle the substitution of Scenario Outline steps that are missing the examples table" do
      pending('This test requires invalid Gherkin')

      feature_block = [
          "Feature: bad feature",
          '#Scenario Outline: commented scenario',
          '* I am a bad <var>'
      ]
      build_file(feature_block, @file_name)
      expect { CukeSniffer::CLI.new({:features_location => @file_name}) }.to_not raise_error
    end

    it "should be able to accept an examples table in a scenario outline with empty values" do
      feature_block = [
          "Feature: Just a plain old feature",
          "Scenario Outline: Outlinable",
          "Given <outline>",
          "Examples:",
          "|outline|",
          "|       |"
      ]
      build_file(feature_block, @file_name)
      expect { CukeSniffer::CLI.new({:features_location => @file_name}) }.to_not raise_error
    end

  end

  describe "Handling Step Definitions" do
    before(:each) do
      @file_name = "my_step_definitions.rb"
    end

    after(:each) do
      delete_temp_files
    end

    it "should use the passed locations for step definitions to store create step_definitions" do
      step_definition_block = [
          "Given /^I am a step$/ do",
          "end"
      ]
      build_file(step_definition_block, @file_name)
      cuke_sniffer = CukeSniffer::CLI.new({:step_definitions_location => @file_name})
      fail "step definitions were not initialized" if cuke_sniffer.step_definitions == []
    end

    it "should be able to utilize a single step definition file for parsing" do
      step_definition_block = [
          "Given /^I am a step$/ do",
          "end"
      ]
      build_file(step_definition_block, @file_name)
      cuke_sniffer = CukeSniffer::CLI.new({:step_definitions_location => @file_name})
      actual_step_definitions = remove_rules(cuke_sniffer.step_definitions)
      actual_step_definitions.should == [CukeSniffer::StepDefinition.new("#@file_name:1", step_definition_block)]
    end

    it "should catalog all calls from scenarios and nested step definition calls on a step definition" do
      feature_block = [
          "Feature: Test Feature",
          "Scenario: Empty Scenario",
          "Given live step",
          "When nested step"
      ]
      @file_name = "my_feature.feature"
      build_file(feature_block, @file_name)
      feature = CukeSniffer::Feature.new(@file_name)

      step_definition_block = [
          "When /^live step$/ do",
          "end"
      ]
      live_step_definition = CukeSniffer::StepDefinition.new("LiveStep:1", step_definition_block)

      step_definition_block = [
          "When /^nested step$/ do",
          "steps \"When live step\"",
          "end"
      ]
      step_definition_with_nested_call = CukeSniffer::StepDefinition.new("NestedStep:1", step_definition_block)

      cuke_sniffer = CukeSniffer::CLI.new()
      cuke_sniffer.features = [feature]
      cuke_sniffer.step_definitions = [live_step_definition, step_definition_with_nested_call]

      cuke_sniffer.catalog_step_calls
      cuke_sniffer.step_definitions.first.calls.count.should == 2
    end

    it "should read every line of multiple step definition and segment those lines into steps." do
      step_definition_block = [
          "Given /^I am a step$/ do",
          "  puts 'stuff'",
          "end",
          "",
          "And /^I too am a step$/ do",
          " if true {",
          "   puts 'no'",
          " }",
          "end"
      ]
      build_file(step_definition_block, @file_name)

      cuke_sniffer = CukeSniffer::CLI.new({:step_definitions_location => @file_name})
      cuke_sniffer.step_definitions.count.should == 2
    end

    it "should be able to identify step definitions that are defined in parentheses." do
      step_definition_block = [
          "Given(/^I am a step$/) do",
          "  puts 'stuff'",
          "end"
      ]
      build_file(step_definition_block, @file_name)

      cuke_sniffer = CukeSniffer::CLI.new({:step_definitions_location => @file_name})
      cuke_sniffer.step_definitions.count.should == 1
    end

    it "should create a list of step definition objects from a step definition file." do
      step_definition_block = [
          "Given /^I am a step$/ do",
          "puts 'stuff'",
          "end"
      ]
      build_file(step_definition_block, @file_name)
      expected_step_definitions = [CukeSniffer::StepDefinition.new(@file_name + ":1", step_definition_block)]
      cuke_sniffer = CukeSniffer::CLI.new({:step_definitions_location => @file_name})
      actual_step_definitions = remove_rules(cuke_sniffer.step_definitions)
      actual_step_definitions.should == expected_step_definitions
    end

    it "should determine if it is below the step definition threshold" do
      cuke_sniffer = CukeSniffer::CLI.new()
      start_threshold = CukeSniffer::Constants::THRESHOLDS["Project"]
      CukeSniffer::Constants::THRESHOLDS["Project"] = 200
      cuke_sniffer.summary[:total_score] = 199
      cuke_sniffer.good?.should == true
      CukeSniffer::Constants::THRESHOLDS["Project"] = start_threshold
    end

    it "should determine the percentage of problems compared to the step definition threshold" do
      cuke_sniffer = CukeSniffer::CLI.new()
      start_threshold = CukeSniffer::Constants::THRESHOLDS["Project"]
      CukeSniffer::Constants::THRESHOLDS["Project"] = 2
      cuke_sniffer.summary[:total_score] = 3
      cuke_sniffer.problem_percentage.should == (3.0/2.0)
      CukeSniffer::Constants::THRESHOLDS["Project"] = start_threshold
    end

    it "should not consider a step generated from a commented example row when categorizing step calls" do
      feature_file_name = "my_feature.feature"
      feature_block = [
          "Feature: Just a plain old feature",
          "Scenario Outline: Outlinable",
          "Given <outline>",
          "Examples:",
          "|outline|",
          "#| John      |"
      ]
      build_file(feature_block, feature_file_name)


      step_definition_block = [
          "Given /^John$/ do",
          "end"
      ]
      step_definition_file_name = "my_steps.rb"
      build_file(step_definition_block, step_definition_file_name)
      cuke_sniffer = CukeSniffer::CLI.new({:features_location => feature_file_name, :step_definitions_location => step_definition_file_name})
      cuke_sniffer.step_definitions.first.calls.should == {}
      File.delete(feature_file_name)
      File.delete(step_definition_file_name)
    end
  end

  describe "Handling Dead Step Definitions" do
    before(:each) do
      @file_name = "my_step_definitions.rb"
    end

    after(:each) do
      delete_temp_files
    end

    it "should identify dead step definitions" do
      step_definition_block = [
          "Given /^I am a dead step$/ do",
          "",
          "end"]
      build_file(step_definition_block, @file_name)

      cuke_sniffer = CukeSniffer::CLI.new()
      dead_steps = cuke_sniffer.get_dead_steps
      dead_steps[:total].should >= 1
      dead_steps.empty?.should be_false
    end

    it "should disregard multiple white space between the Given/When/Then and the actual content of the step when cataloging step definitions and should not be considered a dead step" do
      feature_block = [
          "Feature: Temp",
          "Scenario: white space",
          "Given     blarg",
      ]

      build_file(feature_block, @file_name)

      feature = CukeSniffer::Feature.new(@file_name)

      step_definition_block = [
          "Given /^blarg$/ do",
          "end"
      ]
      step_definition = CukeSniffer::StepDefinition.new("location.rb:3", step_definition_block)

      cuke_sniffer = CukeSniffer::CLI.new()
      cuke_sniffer.features = [feature]
      cuke_sniffer.step_definitions = [step_definition]

      cuke_sniffer.catalog_step_calls
      cuke_sniffer.get_dead_steps.should == {:total => 0}
    end

    it "should catalog possible dead steps that don't exactly match a step definition" do
      feature_file_location = "feature_file.feature"
      feature_block = [
          "Feature: feature  file",
          "Scenario: Indirect nested step call",
          'Given Hello "John"'
      ]
      build_file(feature_block, feature_file_location)

      step_definition_file_name = "possible_dead_steps.rb"
      step_definition_block = [
          'Given /^Hello \"(.*)\"$/ do |name|',
          'steps "And Hello #{name}"',
          'end',
          "",
          'And /^Hello John$/ do',
          'end'
      ]
      build_file(step_definition_block, step_definition_file_name)

      cuke_sniffer = CukeSniffer::CLI.new({:features_location => feature_file_location, :step_definitions_location => step_definition_file_name})
      cuke_sniffer.get_dead_steps.should == {:total => 0}

      File.delete(feature_file_location)
      File.delete(step_definition_file_name)
    end

    it "should not consider step definitions that are only dynamically built from outlines to be dead step definitions. Simple case." do
      feature_file_name = "my_feature.feature"
      feature_block = [
          "Feature: Temp",
          "",
          "Scenario Outline: Testing scenario outlines capturing all steps",
          "Given hello <name>",
          "Examples:",
          "|name|",
          "|John|",
          "|Bill|"
      ]
      build_file(feature_block, feature_file_name)
      feature = CukeSniffer::Feature.new(feature_file_name)

      step_definition_block = [
          "Given /^hello John$/ do",
          "end"
      ]
      john_step_definition = CukeSniffer::StepDefinition.new(@file_name +":1", step_definition_block)

      step_definition_block = [
          "Given /^hello Bill$/ do",
          "end"
      ]
      bill_step_definition = CukeSniffer::StepDefinition.new(@file_name +":3", step_definition_block)

      cuke_sniffer = CukeSniffer::CLI.new()
      cuke_sniffer.features = [feature]
      cuke_sniffer.step_definitions = [john_step_definition, bill_step_definition]

      cuke_sniffer.catalog_step_calls
      cuke_sniffer.get_dead_steps.should == {:total => 0}
      File.delete(feature_file_name)
    end

    it "should not consider step definitions that are only dynamically built from outlines to be dead step definitions. Complex case." do
      feature_file_name = "my_feature.feature"
      feature_block = [
          "Feature: Temp",
          "",
          "Scenario Outline: Testing scenario outlines capturing all steps",
          "Given hello <name>",
          "And <name> returns my greeting",
          "Examples:",
          "|name|",
          "|John|",
          "|Bill|"
      ]
      build_file(feature_block, feature_file_name)
      feature = CukeSniffer::Feature.new(feature_file_name)


      step_definitions = []

      ["John", "Bill"].each do |name|
        step_definition_block = [
            "Given /^hello John$/ do",
            "end"
        ]
        greeting_step = CukeSniffer::StepDefinition.new(@file_name + ":1", step_definition_block)

        step_definition_block = [
            "Given /^John returns my greeting$/ do",
            "end"
        ]
        response_step = CukeSniffer::StepDefinition.new(@file_name + ":1", step_definition_block)
        step_definitions << greeting_step
        step_definitions << response_step
      end

      cuke_sniffer = CukeSniffer::CLI.new()
      cuke_sniffer.features = [feature]
      cuke_sniffer.step_definitions = step_definitions

      cuke_sniffer.catalog_step_calls
      cuke_sniffer.get_dead_steps.should == {:total => 0}
      File.delete(feature_file_name)
    end
  end

  describe "Handling Hooks" do
    before(:each) do
      @file_name = "hooks.rb"
      @file_path = Dir.getwd + "/" + @file_name
    end

    after(:each) do
      delete_temp_files
    end

    it "should parse a hooks file" do
      hook_block = [
          "Before do",
          "var = 2",
          "end"
      ]
      build_file(hook_block, @file_name)
      cuke_sniffer = CukeSniffer::CLI.new({:hooks_location => @file_path})
      actual_hooks = remove_rules(cuke_sniffer.hooks)
      actual_hooks.should == [CukeSniffer::Hook.new(@file_path + ":1", hook_block)]
    end

    it "should parse a hooks file with multiple hooks" do
      hook_block = [
          "Before do",
          "var = 2",
          "end",
          "Before('@tag') do",
          "var = 2",
          "end"
      ]
      build_file(hook_block, @file_name)
      cuke_sniffer = CukeSniffer::CLI.new({:hooks_location => @file_path})
      actual_hooks = remove_rules(cuke_sniffer.hooks)
      actual_hooks.should == [
          CukeSniffer::Hook.new(@file_path + ":1", hook_block[0..2]),
          CukeSniffer::Hook.new(@file_path + ":4", hook_block[3..5])
      ]
    end

    it "should parse hooks that exist in any ruby file" do
      hook_block = [
          "Before do",
          "var = 2",
          "end"
      ]
      @file_name = "env.rb"
      build_file(hook_block, @file_name)
      cuke_sniffer = CukeSniffer::CLI.new({:hooks_location => Dir.getwd + "/" + @file_name})
      actual_hooks = remove_rules(cuke_sniffer.hooks)
      actual_hooks.should == [CukeSniffer::Hook.new(Dir.getwd + "/"+ @file_name +":1", hook_block)]
    end

    it "should include hooks rules in the improvements list" do
      hook_block = [
          "Before do",
          "end"
      ]
      build_file(hook_block, @file_name)
      cuke_sniffer = CukeSniffer::CLI.new({:hooks_location => Dir.getwd})
      cuke_sniffer.improvement_list.should_not be_empty
    end

  end

  describe "Building Rules" do

    it "should build a list of rules."do
      cuke_sniffer = CukeSniffer::CLI.new()

      cuke_sniffer.rules.size.should == RULES.size
      cuke_sniffer.rules.first.phrase.should_not == nil
      cuke_sniffer.rules.first.score.should_not == nil
      cuke_sniffer.rules.first.enabled.should == true
    end

    it "should build a rule summary for each rule" do
      multiple_rule_set = {}
      3.times do |n|
        multiple_rule_set[n] = {}
        multiple_rule_set[n][:enabled] = true
        multiple_rule_set[n][:phrase] = "phrase: " + n.to_s
        multiple_rule_set[n][:score] = n
      end

      rules = CukeSniffer::CukeSnifferHelper.build_rules(multiple_rule_set)

      multiple_rule_set.count.times do |n|
        rules[n].enabled.should == multiple_rule_set[n][:enabled]
        rules[n].phrase.should == multiple_rule_set[n][:phrase]
        rules[n].score.should == multiple_rule_set[n][:score]
      end
    end

    it "should return an empty array when the rules hash is nil" do
      rules = CukeSniffer::CukeSnifferHelper.build_rules(nil)
      rules.should == []
    end

    it "should return an empty array when the rules hash is an empty hash" do
      rules = CukeSniffer::CukeSnifferHelper.build_rules( {} )
      rules.should == []
    end

    it "should store the symbol" do
      rule = CukeSniffer::CukeSnifferHelper.build_rule(:symbol, {})
      rule.symbol.should == :symbol
    end

    it "should not build rules with conditions when the rule has no conditions" do
      rule_hash = {
          :enabled => true,
          :phrase => "Rule phrase.",
          :score => 0
      }
      rule = CukeSniffer::CukeSnifferHelper.build_rule(:symbol, rule_hash)
      rule.conditions.should == {}
    end

    it "should build rules with conditions when the rule has conditions" do
      min = 1
      max = 7
      rule_hash = {
          :enabled => true,
          :phrase => "Phrase",
          :score => 0,
          :max => max,
          :min => min
      }
      rule = CukeSniffer::CukeSnifferHelper.build_rule(:symbol, rule_hash)
      rule.conditions[:max].should == max
      rule.conditions[:min].should == min
    end
    it "should assign a project location when one is provided" do
      project_location = "my_project"

      cuke_sniffer = CukeSniffer::CLI.new({:project_location => project_location})

      cuke_sniffer.features_location.should == project_location
      cuke_sniffer.step_definitions_location.should == project_location
      cuke_sniffer.hooks_location.should == project_location
    end

    it "should override the features location when project location and feature location are provided" do
      project_location = "my_project"
      features_location = "my_project/features"
      cuke_sniffer = CukeSniffer::CLI.new({:project_location => project_location,
                                   :features_location => features_location})

      cuke_sniffer.features_location.should == features_location
      cuke_sniffer.step_definitions_location.should == project_location
      cuke_sniffer.hooks_location.should == project_location
    end
    it "should override the step definition location when the project location and the step definition location are provided" do
      project_location = "my_project"
      step_definitions_location = "my_project/steps"
      cuke_sniffer = CukeSniffer::CLI.new({:project_location => project_location,
                                   :step_definitions_location => step_definitions_location})

      cuke_sniffer.features_location.should == project_location
      cuke_sniffer.step_definitions_location.should == step_definitions_location
      cuke_sniffer.hooks_location.should == project_location
    end
    it "should override the hooks location when the project location and the hooks location are provided" do
      project_location = "my_project"
      hooks_location = "my_project/hooks"
      cuke_sniffer = CukeSniffer::CLI.new({:project_location => project_location,
                                   :hooks_location => hooks_location})

      cuke_sniffer.features_location.should == project_location
      cuke_sniffer.step_definitions_location.should == project_location
      cuke_sniffer.hooks_location.should == hooks_location
    end
  end
end




