require 'spec_helper'


describe CukeSniffer do


  before(:each) do
    @features_location = File.dirname(__FILE__) + "/../../features/scenarios"
    @step_definitions_location = File.dirname(__FILE__) + "/../../features/step_definitions"
  end

  it "should be able to utilize a single feature file for parsing" do
    file_name = "single_feature.feature"
    file = File.open(file_name, "w")
    file.puts("Feature: I am the cheese that stands alone")
    file.close
    cuke_sniffer = CukeSniffer::CLI.new(file_name, nil)
    cuke_sniffer.features.should == [CukeSniffer::Feature.new(file_name)]
    File.delete(file_name)
  end

  it "should be able to utilize a single step definition file for parsing" do
    file_name = "single_steps.rb"
    file = File.open(file_name, "w")
    raw_code = [
        "Given /^I am a step$/ do",
        "end"
    ]
    raw_code.each { |line| file.puts line }
    file.close
    cuke_sniffer = CukeSniffer::CLI.new(nil, file_name)
    cuke_sniffer.step_definitions.should == [CukeSniffer::StepDefinition.new("single_steps.rb:1", raw_code)]
    File.delete(file_name)
  end

  it "should parse a hooks file" do
    file_name = "hooks.rb"
    file = File.open(file_name, "w")
    raw_code = [
        "Before do",
        "var = 2",
        "end"
    ]
    raw_code.each { |line| file.puts line }
    file.close
    cuke_sniffer = CukeSniffer::CLI.new(nil, nil, Dir.getwd + "/hooks.rb")
    cuke_sniffer.hooks.should == [CukeSniffer::Hook.new(Dir.getwd + "/hooks.rb:1", raw_code)]
    File.delete(file_name)
  end

  it "should parse a hooks file with multiple hooks" do
    file_name = "hooks.rb"
    file = File.open(file_name, "w")
    raw_code = [
        "Before do",
        "var = 2",
        "end",
        "Before('@tag') do",
        "var = 2",
        "end"
    ]
    raw_code.each { |line| file.puts line }
    file.close
    cuke_sniffer = CukeSniffer::CLI.new(nil, nil, Dir.getwd + "/hooks.rb")
    cuke_sniffer.hooks.should == [CukeSniffer::Hook.new(Dir.getwd + "/hooks.rb:1", raw_code[0..2]), CukeSniffer::Hook.new(Dir.getwd + "/hooks.rb:4", raw_code[3..5])]
    File.delete(file_name)
  end

  it "should parse hooks that exist in any ruby file" do
    file_name = "env.rb"
    file = File.open(file_name, "w")
    raw_code = [
        "Before do",
        "var = 2",
        "end"
    ]
    raw_code.each { |line| file.puts line }
    file.close
    cuke_sniffer = CukeSniffer::CLI.new(nil, nil, Dir.getwd + "/env.rb")
    cuke_sniffer.hooks.should == [CukeSniffer::Hook.new(Dir.getwd + "/env.rb:1", raw_code)]
    File.delete(file_name)
  end

  it "should use the passed locations for features and steps and store those create objects" do
    cuke_sniffer = CukeSniffer::CLI.new(@features_location, @step_definitions_location)
    fail "features were not initialized" if cuke_sniffer.features == {}
    fail "step definitions were not initialized" if cuke_sniffer.step_definitions == []
  end

  it "should catalog all calls a scenario and nested step definition calls" do
    cuke_sniffer = CukeSniffer::CLI.new(@features_location, @step_definitions_location)
    scenario_block = [
        "Scenario: Empty Scenario",
        "Given live step",
        "When nested step"
    ]
    scenario = CukeSniffer::Scenario.new("ScenarioLocation:3", scenario_block)

    my_feature = CukeSniffer::Feature.new("#@features_location/simple_calculator.feature")
    my_feature.scenarios = [scenario]
    cuke_sniffer.features = [my_feature]

    raw_code = ["When /^live step$/ do", "end"]
    live_step_definition = CukeSniffer::StepDefinition.new("LiveStep:1", raw_code)

    raw_code = ["When /^nested step$/ do",
                "steps \"When live step\"",
                "end"]
    nested_step_definition = CukeSniffer::StepDefinition.new("NestedStep:1", raw_code)

    my_step_definitions = [live_step_definition, nested_step_definition]

    cuke_sniffer.step_definitions = my_step_definitions
    cuke_sniffer.catalog_step_calls
    cuke_sniffer.step_definitions[0].calls.count.should == 2
  end

  it "should identify dead step definitions" do
    lines = ["Given /^I am a dead step$/ do", "", "end"]
    file_name = "dead_steps.rb"
    file = File.open(file_name, "w")
    lines.each { |line| file.puts(line) }
    file.close

    cuke_sniffer = CukeSniffer::CLI.new(@features_location, Dir.getwd)
    dead_steps = cuke_sniffer.get_dead_steps
    dead_steps[:total].should >= 1
    dead_steps.empty?.should be_false
    File.delete(file_name)
  end

  it "should read every line of multiple step definition and segment those lines into steps." do
    file_name = "my_steps.rb"
    file = File.open(file_name, "w")
    file.puts("Given /^I am a step$/ do")
    file.puts("  puts 'stuff'")
    file.puts("end")
    file.puts("")
    file.puts("And /^I too am a step$/ do")

    file.puts("if true {")
    file.puts("puts 'no'")
    file.puts("}")
    file.puts("end")
    file.close

    cuke_sniffer = CukeSniffer::CLI.new(nil, file_name)
    cuke_sniffer.step_definitions.count.should == 2

    File.delete(file_name)
  end

  it "should create a list of step definition objects from a step definition file." do
    file_name = "my_steps.rb"
    file = File.open(file_name, "w")
    file.puts("Given /^I am a step$/ do")
    file.puts("  puts 'stuff'")
    file.puts("end")
    file.close

    expected_step_definitions = [
        CukeSniffer::StepDefinition.new("my_steps.rb:1", ["Given /^I am a step$/ do", "puts 'stuff'", "end"])
    ]
    cuke_sniffer = CukeSniffer::CLI.new(nil, file_name)
    step_definitions = cuke_sniffer.step_definitions

    step_definitions.should == expected_step_definitions
    File.delete(file_name)
  end

  it "should determine if it is above the scenario threshold" do
    cuke_sniffer = CukeSniffer::CLI.new(@features_location, @step_definitions_location)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["Project"]
    CukeSniffer::Constants::THRESHOLDS["Project"] = 2
    cuke_sniffer.good?.should == false
    CukeSniffer::Constants::THRESHOLDS["Project"] = start_threshold
  end

  it "should determine if it is below the step definition threshold" do
    cuke_sniffer = CukeSniffer::CLI.new(@features_location, @step_definitions_location, nil)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["Project"]
    CukeSniffer::Constants::THRESHOLDS["Project"] = 200
    cuke_sniffer.good?.should == true
    CukeSniffer::Constants::THRESHOLDS["Project"] = start_threshold
  end

  it "should determine the percentage of problems compared to the step definition threshold" do
    cuke_sniffer = CukeSniffer::CLI.new(@features_location, @step_definitions_location)
    start_threshold = CukeSniffer::Constants::THRESHOLDS["Project"]
    CukeSniffer::Constants::THRESHOLDS["Project"] = 2
    cuke_sniffer.summary[:total_score] = 3
    cuke_sniffer.problem_percentage.should == (3.0/2.0)
    CukeSniffer::Constants::THRESHOLDS["Project"] = start_threshold
  end

  it "should generate a well formed xml of the content by respectable sections" do
    cuke_sniffer = CukeSniffer::CLI.new(@features_location, @step_definitions_location)
    file_name = "my_xml.xml"
    cuke_sniffer.output_xml(file_name)
    File.exists?(file_name)
    File.delete(file_name)
  end

  it "should generate an html report" do
    cuke_sniffer = CukeSniffer::CLI.new(@features_location, @step_definitions_location)
    file_name = "my_html.html"
    cuke_sniffer.output_html(file_name)
    File.exists?(file_name)
    File.delete(file_name)
  end

  it "should not consider step definitions that are only dynamically built from outlines to be dead step definitions. Simple case." do
    my_feature_file = "temp.feature"
    file = File.open(my_feature_file, "w")
    file.puts "Feature: Temp"
    file.puts ""
    file.puts "Scenario Outline: Testing scenario outlines capturing all steps"
    file.puts "Given hello <name>"
    file.puts "Examples:"
    file.puts "|name|"
    file.puts "|John|"
    file.puts "|Bill|"
    file.close

    feature = CukeSniffer::Feature.new(my_feature_file)

    raw_code = ["Given /^hello John$/ do",
                "end"]
    john_step_definition = CukeSniffer::StepDefinition.new("location.rb:1", raw_code)

    raw_code = ["Given /^hello Bill$/ do",
                "end"]
    bill_step_definition = CukeSniffer::StepDefinition.new("location.rb:3", raw_code)

    cuke_sniffer = CukeSniffer::CLI.new(@features_location, @step_definitions_location)
    cuke_sniffer.features = [feature]
    cuke_sniffer.step_definitions = [john_step_definition, bill_step_definition]

    cuke_sniffer.catalog_step_calls
    cuke_sniffer.get_dead_steps.should == {:total => 0}
    File.delete(my_feature_file)
  end

  it "should not consider step definitions that are only dynamically built from outlines to be dead step definitions. Complex case." do
    my_feature_file = "temp.feature"
    file = File.open(my_feature_file, "w")
    file.puts "Feature: Temp"
    file.puts ""
    file.puts "Scenario Outline: Testing scenario outlines capturing all steps"
    file.puts "Given hello <name>"
    file.puts "And <name> returns my greeting"
    file.puts "Examples:"
    file.puts "|name|"
    file.puts "|John|"
    file.puts "|Bill|"
    file.close

    feature = CukeSniffer::Feature.new(my_feature_file)

    raw_code = ["Given /^hello John$/ do",
                "end"]
    john_step_definition = CukeSniffer::StepDefinition.new("location.rb:1", raw_code)

    raw_code = ["Given /^John returns my greeting$/ do",
                "end"]
    john_reply_step_definition = CukeSniffer::StepDefinition.new("location.rb:1", raw_code)

    raw_code = ["Given /^hello Bill$/ do",
                "end"]
    bill_step_definition = CukeSniffer::StepDefinition.new("location.rb:3", raw_code)

    raw_code = ["Given /^Bill returns my greeting$/ do",
                "end"]
    bill_reply_step_definition = CukeSniffer::StepDefinition.new("location.rb:1", raw_code)

    cuke_sniffer = CukeSniffer::CLI.new(@features_location, @step_definitions_location)
    cuke_sniffer.features = [feature]
    cuke_sniffer.step_definitions = [john_step_definition, john_reply_step_definition, bill_step_definition, bill_reply_step_definition]

    cuke_sniffer.catalog_step_calls
    cuke_sniffer.get_dead_steps.should == {:total => 0}
    File.delete(my_feature_file)
  end

  it "should disregard multiple white space between the Given/When/Then and the actual content of the step when cataloging step definitions and should not be considered a dead step" do
    my_feature_file = "temp.feature"
    file = File.open(my_feature_file, "w")
    file.puts "Feature: Temp"
    file.puts "Scenario: white space"
    file.puts "Given     blarg"
    file.close

    feature = CukeSniffer::Feature.new(my_feature_file)

    raw_code = ["Given /^blarg$/ do",
                "end"]
    step_definition = CukeSniffer::StepDefinition.new("location.rb:3", raw_code)

    cuke_sniffer = CukeSniffer::CLI.new(@features_location, @step_definitions_location)
    cuke_sniffer.features = [feature]
    cuke_sniffer.step_definitions = [step_definition]

    cuke_sniffer.catalog_step_calls
    cuke_sniffer.get_dead_steps.should == {:total => 0}
    File.delete(my_feature_file)
  end

  it "should catalog possible dead steps that don't exactly match a step definition" do
    feature_file_location = "feature_file.feature"
    file = File.open(feature_file_location, "w")
    file.puts("Feature: feature  file")
    file.puts("Scenario: Indirect nested step call")
    file.puts('Given Hello "John"')
    file.close

    step_definition_file_name = "possible_dead_steps.rb"
    file = File.open(step_definition_file_name, "w")

    file.puts('Given /^Hello \"(.*)\"$/ do |name|')
    file.puts('steps "And Hello #{name}"')
    file.puts('end')
    file.puts("")
    file.puts('And /^Hello John$/ do')
    file.puts('end')
    file.close

    cuke_sniffer = CukeSniffer::CLI.new(feature_file_location, step_definition_file_name)
    cuke_sniffer.get_dead_steps.should == {:total => 0}

    File.delete(feature_file_location)
    File.delete(step_definition_file_name)
  end

  it "should put hooks rules into the improvements list" do
    hooks_file_location = "hooks_file.rb"
    lines = ["Before do", "end"]
    build_file(lines, hooks_file_location)

    cuke_sniffer = CukeSniffer::CLI.new(nil, nil, hooks_file_location)
    File.delete hooks_file_location

    cuke_sniffer.improvement_list.should_not be_empty
  end

  it "should be able to handle the substitution of Scenario Outline steps that are missing the examples table" do
    lines = ["Feature: bad feature",
             '#Scenario Outline: commented scenario',
             '* I am a bad <var>'
    ]
    file_name = "temp_feature.feature"
    build_file(lines, file_name)
    lambda { CukeSniffer::CLI.new(file_name, nil, nil) }.should_not raise_error
    File.delete(file_name)
  end

  it "should be able to accept an examples table in a scenario outline with empty values" do
    lines = ["Feature: Just a plain old feature",
             "Scenario Outline: Outlinable",
             "Given <outline>",
             "Examples:",
             "|outline|",
             "|       |"
    ]
    file_name = "temp_feature.feature"
    build_file(lines, file_name)
    lambda { CukeSniffer::CLI.new(file_name, nil, nil) }.should_not raise_error
    File.delete(file_name)
  end

  it "should not consider a step generated from a commented example row when categorizing step calls" do
    lines = ["Feature: Just a plain old feature",
             "Scenario Outline: Outlinable",
             "Given <outline>",
             "Examples:",
             "|outline|",
             "#| John      |"
    ]
    feature_file_name = "temp_feature.feature"
    build_file(lines, feature_file_name)


    steps = [
        "Given /^John$/ do",
        "end"
    ]
    step_definition_file_name = "temp_steps.rb"
    build_file(steps, step_definition_file_name)
    cuke_sniffer = CukeSniffer::CLI.new(feature_file_name, step_definition_file_name, nil)
    cuke_sniffer.step_definitions.first.calls.should == {}
    File.delete(feature_file_name)
    File.delete(step_definition_file_name)
  end

  it "contains all of the rules."do
    cuke_sniffer = CukeSniffer::CLI.new()

    cuke_sniffer.rules.size.should == RULES.size
    cuke_sniffer.rules.first.phrase.should_not == nil
    cuke_sniffer.rules.first.score.should_not == nil
    cuke_sniffer.rules.first.enabled.should == true
  end

  it "should have at least one condition in the rules." do
    cuke_sniffer = CukeSniffer::CLI.new()

    has_condition = false
    cuke_sniffer.rules.each do |rule|
      if rule.conditions != nil
        has_condition = true
      end
    end

    has_condition.should == true
  end

  describe "build_rule" do

    single_rule_set = {
        :one => {
            :enabled => true,
            :phrase => "Scenario Outline with no examples.",
            :score => FATAL
        }
    }

    multiple_rule_set = {
        :one => {
            :enabled => true,
            :phrase => "Scenario Outline with a single example.",
            :score => FATAL
        },
        :two => {
            :enabled => false,
            :phrase => "Scenario Outline with multiple examples.",
            :score => WARNING
        },
        :three => {
            :enabled => true,
            :phrase => "Scenario Outline with the last example.",
            :score => INFO,
            :max => 7,
            :min => 1
        }
    }

    it "produces rule summaries based on the provided rules" do
      rules = CukeSniffer::CLI.build_rules(multiple_rule_set)

      rules[0].enabled.should be_true
      rules[0].score.should == FATAL
      rules[0].phrase.should == "Scenario Outline with a single example."

      rules[1].enabled.should be_false
      rules[1].score.should == WARNING
      rules[1].phrase.should == "Scenario Outline with multiple examples."

      rules[2].enabled.should be_true
      rules[2].score.should == INFO
      rules[2].phrase.should == "Scenario Outline with the last example."

    end

    it "produces a rule summary for each rule" do
      CukeSniffer::CLI.build_rules(single_rule_set).size.should == 1
      CukeSniffer::CLI.build_rules(multiple_rule_set).size.should == 3
    end

    it "produces a empty list result when a nil rule is provided" do
      nil_rule_set = nil
      rules = CukeSniffer::CLI.build_rules(nil_rule_set)
      rules.size.should == 0
    end

    it "produces an empty list when an empty set of rules is provided" do
      empty_rule_set = {  }
      rules = CukeSniffer::CLI.build_rules(empty_rule_set)
      rules.size.should == 0
    end

    it "produces a rule summary with an empty conditions list when a rule has no conditions"do
      rules = CukeSniffer::CLI.build_rules(multiple_rule_set)
      rules[1].conditions.should == {}
    end

    it "produces a condition in the rule summary for each condition in the rule"do
      rules = CukeSniffer::CLI.build_rules(multiple_rule_set)
      rules[2].conditions[:max].should == 7
      rules[2].conditions[:min].should == 1

    end
  end

  describe "output_html" do

    it "should order the hooks during output to html" do
      hook_raw_code = ["AfterConfiguration do",
                       "1+1",
                       "end"]
      hook_location = "location.rb:1"

      cuke_sniffer = CukeSniffer::CLI.new()
      big_hook = CukeSniffer::Hook.new(hook_location, hook_raw_code)
      big_hook.score = 10
      little_hook = CukeSniffer::Hook.new(hook_location, hook_raw_code)
      little_hook.score = big_hook.score - 1
      cuke_sniffer.hooks = [little_hook, big_hook]
      cuke_sniffer.output_html

      cuke_sniffer.hooks.should == [big_hook, little_hook]
    end

    it "should order the step definitions during output to html" do
      step_def_raw_code = ["When /^the second number is 1$/ do",
                           "@second_number = 1",
                           "end"]
      step_def_location = "path/path/path/my_steps.rb:1"

      cuke_sniffer = CukeSniffer::CLI.new()
      big_step = CukeSniffer::StepDefinition.new(step_def_location, step_def_raw_code)
      big_step.score = 10
      little_step = CukeSniffer::StepDefinition.new(step_def_location, step_def_raw_code)
      little_step.score = big_step.score - 1
      cuke_sniffer.step_definitions = [little_step, big_step]
      cuke_sniffer.output_html

      cuke_sniffer.step_definitions.should == [big_step, little_step]
    end

    it "should order the rules during output to html (descending)" do
      cuke_sniffer = CukeSniffer::CLI.new()
      big_rule = CukeSniffer::Rule.new()
      big_rule.score = 100
      little_rule = CukeSniffer::Rule.new()
      little_rule.score = big_rule.score - 1
      cuke_sniffer.rules = [little_rule, big_rule]
      cuke_sniffer.output_html

      cuke_sniffer.rules.should == [big_rule, little_rule]
    end

    it "should order the features during output to html" do
      file_name = "my_feature.feature"
      build_file(["Feature: I am a feature"], file_name)

      cuke_sniffer = CukeSniffer::CLI.new()
      big_feature = CukeSniffer::Feature.new(file_name)
      big_feature.total_score = 20
      little_feature = CukeSniffer::Feature.new(file_name)
      little_feature.total_score = big_feature.total_score - 1
      cuke_sniffer.features = [little_feature, big_feature]
      cuke_sniffer.output_html

      cuke_sniffer.features.should == [big_feature, little_feature]

      File.delete(file_name)
    end

  end

  describe "convert_array_condition_into_list_of_strings" do

    it "breaks the array into groups of five" do
      cuke_sniffer = CukeSniffer::CLI.new()
      input = ["hi","how","are","you","should","and","become","wow", "boo","moo"]

      cuke_sniffer.convert_array_condition_into_list_of_strings(input).should match_array(["hi, how, are, you, should","and, become, wow, boo, moo"])

    end

    it "puts remainder into last group" do
      cuke_sniffer = CukeSniffer::CLI.new()
      input = ["hi","how","are","you","should","and","become","wow", "boo","moo","entry"]

      cuke_sniffer.convert_array_condition_into_list_of_strings(input).should match_array(["hi, how, are, you, should","and, become, wow, boo, moo","entry"])

      input = ["hi","how","are","you"]

      cuke_sniffer.convert_array_condition_into_list_of_strings(input).should match_array(["hi, how, are, you"])

    end
  end
end




