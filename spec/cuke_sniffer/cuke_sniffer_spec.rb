require 'spec_helper'

describe CukeSniffer do

  before(:each) do
    @features_location = File.dirname(__FILE__) + "/../../features/scenarios"
    @step_definitions_location = File.dirname(__FILE__) + "/../../features/step_definitions"
  end

  describe "Handling Project" do

    it "should determine if it is above the project threshold" do
      cuke_sniffer = CukeSniffer::CLI.new({:features_location=> @features_location,:step_definitions_location => @step_definitions_location})
      start_threshold = CukeSniffer::Constants::THRESHOLDS["Project"]
      CukeSniffer::Constants::THRESHOLDS["Project"] = 2
      cuke_sniffer.summary[:total_score] = 3
      cuke_sniffer.good?.should == false
      CukeSniffer::Constants::THRESHOLDS["Project"] = start_threshold
    end
  end

  describe "Handling Features" do

    before(:each) do
      @file_name = "my_feature.feature"
    end

    after(:each) do
      File.delete(@file_name) if File.exist?(@file_name)
    end

    it "should use the passed locations for features to store create features" do
      cuke_sniffer = CukeSniffer::CLI.new({:features_location=> @features_location})
      fail "features were not initialized" if cuke_sniffer.features == {}
    end

    it "should be able to utilize a single feature file for parsing" do
      feature_block = ["Feature: I am the only feature."]
      build_file(feature_block, @file_name)
      cuke_sniffer = CukeSniffer::CLI.new({:features_location=>@file_name})
      actual_features = remove_rules(cuke_sniffer.features)
      actual_features.should == [CukeSniffer::Feature.new(@file_name)]
    end

    it "should be able to handle the substitution of Scenario Outline steps that are missing the examples table" do
      feature_block = [
          "Feature: bad feature",
          '#Scenario Outline: commented scenario',
          '* I am a bad <var>'
      ]
      build_file(feature_block, @file_name)
      expect { CukeSniffer::CLI.new({:features_location=>@file_name}) }.to_not raise_error
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
      expect { CukeSniffer::CLI.new({:features_location=> @features_location}) }.to_not raise_error
    end

  end

  describe "Handling Step Definitions" do
    before(:each) do
      @file_name = "my_step_definitions.rb"
    end

    after(:each) do
      File.delete(@file_name) if File.exist?(@file_name)
    end

    it "should use the passed locations for step definitions to store create step_definitions" do
      cuke_sniffer = CukeSniffer::CLI.new({:step_definitions_location=> @step_definitions_location})
      fail "step definitions were not initialized" if cuke_sniffer.step_definitions == []
    end

    it "should be able to utilize a single step definition file for parsing" do
      step_definition_block = [
          "Given /^I am a step$/ do",
          "end"
      ]
      build_file(step_definition_block, @file_name)
      cuke_sniffer = CukeSniffer::CLI.new({:step_definitions_location=> @file_name})
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

      cuke_sniffer = CukeSniffer::CLI.new({:features_location => @features_location ,:step_definitions_location=> @step_definitions_location})
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

      cuke_sniffer = CukeSniffer::CLI.new({:step_definitions_location=> @file_name})
      cuke_sniffer.step_definitions.count.should == 2
    end

    it "should create a list of step definition objects from a step definition file." do
      step_definition_block = [
          "Given /^I am a step$/ do",
          "puts 'stuff'",
          "end"
      ]
      build_file(step_definition_block, @file_name)
      expected_step_definitions = [CukeSniffer::StepDefinition.new(@file_name + ":1", step_definition_block)]
      cuke_sniffer = CukeSniffer::CLI.new({:step_definitions_location=> @file_name})
      actual_step_definitions = remove_rules(cuke_sniffer.step_definitions)
      actual_step_definitions.should == expected_step_definitions
    end

    it "should determine if it is below the step definition threshold" do
      cuke_sniffer = CukeSniffer::CLI.new({:features_location => @features_location ,:step_definitions_location=> @step_definitions_location})
      start_threshold = CukeSniffer::Constants::THRESHOLDS["Project"]
      CukeSniffer::Constants::THRESHOLDS["Project"] = 200
      cuke_sniffer.good?.should == true
      CukeSniffer::Constants::THRESHOLDS["Project"] = start_threshold
    end

    it "should determine the percentage of problems compared to the step definition threshold" do
      cuke_sniffer = CukeSniffer::CLI.new({:features_location => @features_location ,:step_definitions_location=> @step_definitions_location})
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
      cuke_sniffer = CukeSniffer::CLI.new({:features_location=>feature_file_name, :step_definitions_location=>step_definition_file_name})
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
      File.delete(@file_name) if File.exist?(@file_name)
    end

    it "should identify dead step definitions" do
      step_definition_block = [
          "Given /^I am a dead step$/ do",
          "",
          "end"]
      build_file(step_definition_block, @file_name)

      cuke_sniffer = CukeSniffer::CLI.new({:features_location=>@features_location, :step_definitions_location=>Dir.getwd})
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

      cuke_sniffer = CukeSniffer::CLI.new({:features_location=>feature_file_location, :step_definitions_location=>step_definition_file_name})
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

      cuke_sniffer = CukeSniffer::CLI.new({:features_location => @features_location ,:step_definitions_location=> @step_definitions_location})
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
      File.delete(@file_name) if File.exist?(@file_name)
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
      cuke_sniffer = CukeSniffer::CLI.new({:hooks_location =>  Dir.getwd + "/" + @file_name})
      actual_hooks = remove_rules(cuke_sniffer.hooks)
      actual_hooks.should == [CukeSniffer::Hook.new(Dir.getwd + "/"+ @file_name +":1", hook_block)]
    end

    it "should include hooks rules in the improvements list" do
      hook_block = [
          "Before do",
          "end"
      ]
      build_file(hook_block, @file_name)
      cuke_sniffer = CukeSniffer::CLI.new({:hooks_location =>  Dir.getwd})
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

      rules = CukeSniffer::CLI.build_rules(multiple_rule_set)

      multiple_rule_set.count.times do |n|
        rules[n].enabled.should == multiple_rule_set[n][:enabled]
        rules[n].phrase.should == multiple_rule_set[n][:phrase]
        rules[n].score.should == multiple_rule_set[n][:score]
      end
    end

    it "should return an empty array when the rules hash is nil" do
      rules = CukeSniffer::CLI.build_rules(nil)
      rules.should == []
    end

    it "should return an empty array when the rules hash is an empty hash" do
      rules = CukeSniffer::CLI.build_rules( {} )
      rules.should == []
    end

    it "should not build rules with conditions when the rule has no conditions" do
      rule_hash = {
          :enabled => true,
          :phrase => "Rule phrase.",
          :score => 0
      }
      rule = CukeSniffer::CLI.build_rule(rule_hash)
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
      rule = CukeSniffer::CLI.build_rule(rule_hash)
      rule.conditions[:max].should == max
      rule.conditions[:min].should == min
    end

  end

  describe "HTML output" do
    before(:each) do
      @file_name = "my_html.html"
    end

    after(:each) do
      File.delete(@file_name) if File.exist?(@file_name)
    end

    it "should generate an html report" do
      cuke_sniffer = CukeSniffer::CLI.new({:features_location => @features_location ,:step_definitions_location=> @step_definitions_location})
      cuke_sniffer.output_html(@file_name)
      File.exists?(@file_name).should == true
    end

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
    it "produces a no objects to sniff message when there is no feature" do
      temp_dir =  make_dir("scenarios/temp")
      cuke_sniffer = CukeSniffer::CLI.new({:features_location => temp_dir})
      cuke_sniffer.output_html

      build_nokogiri_from_cuke_sniffer_results.xpath("//div[@id = 'features_data']/div[@class = 'notes']").text.should == "There were no Features to sniff in '#{cuke_sniffer.features_location}'!"

      delete_cuke_sniffer_html_and_temp_dir(temp_dir)
    end

    it "produces a no objects to sniff message when there is no step definitions" do
      temp_dir =  make_dir("step_definitions/temp")
      cuke_sniffer = CukeSniffer::CLI.new({:step_definitions_location => temp_dir})
      cuke_sniffer.output_html

      build_nokogiri_from_cuke_sniffer_results.xpath("//div[@id = 'step_definitions_data']/div[@class = 'notes']").text.should == "There were no Step Definitions to sniff in '#{cuke_sniffer.step_definitions_location}'!"

      delete_cuke_sniffer_html_and_temp_dir(temp_dir)
    end

    it "produces a no objects to sniff message when there is no hooks" do
      temp_dir =  make_dir("support/temp")
      cuke_sniffer = CukeSniffer::CLI.new({:hooks_location => temp_dir})

      cuke_sniffer.output_html

      build_nokogiri_from_cuke_sniffer_results.xpath("//div[@id = 'hooks_data']/div[@class = 'notes']").text.should == "There were no Hooks to sniff in '#{cuke_sniffer.hooks_location}'!"

      delete_cuke_sniffer_html_and_temp_dir(temp_dir)
    end

    it "produces a no smells found message when there are no rule violations for features" do
      feature_block = [
          "Feature: Complex Calculator",
          "Scenario: Add two numbers",
          "Given the first number is one",
          "And the second number is one",
          "When the calculator adds",
          "Then the result is two"
      ]
      file_name = "my_feature.feature"
      build_file(feature_block, file_name)

      cuke_sniffer = CukeSniffer::CLI.new({:features_location => file_name})
      cuke_sniffer.output_html

      build_nokogiri_from_cuke_sniffer_results.xpath("//div[@id = 'features_data']/div[@class = 'notes']").text.should == "Excellent! No smells found for Features and Scenarios!"

      cleanup_file_and_html(file_name)
    end

    it "produces a no smells found message when there are no rule violations for step definitions" do
      step_definitions_block = [
          "Given /^I have something$/ do",
          "Some Given line",
          "end",
          "When /^I got something$/ do",
          "Some When line",
          "end",
          "Then /^I return something$/ do",
          "Some Then line",
          "end"
      ]
      file_name = "my_definition_steps.rb"
      build_file(step_definitions_block, file_name)

      cuke_sniffer = CukeSniffer::CLI.new({:step_definitions_location => file_name})
      cuke_sniffer.output_html

      build_nokogiri_from_cuke_sniffer_results.xpath("//div[@id = 'step_definitions_data']/div[@class = 'notes']").text.should == "Excellent! No smells found for Step Definitions!"

      cleanup_file_and_html(file_name)
    end

    it "produces a no smells found message when there are no rule violations for Hooks" do
      hook_block = [
          "After('@tag') do",
          "begin",
          "var = 20",
          "rescue",
          "end",
          "Before('@tag') do",
          "begin",
          "var = 2",
          "rescue",
          "end"
      ]

      file_name = "my_hooks.rb"
      build_file(hook_block, file_name)

      cuke_sniffer = CukeSniffer::CLI.new({:hooks_location => file_name})
      cuke_sniffer.output_html

      build_nokogiri_from_cuke_sniffer_results.xpath("//div[@id = 'hooks_data']/div[@class = 'notes']").text.should == "Excellent! No smells found for Hooks!"

      cleanup_file_and_html(file_name)
    end
  end

  def make_dir(dir_add_on)
    temp_dir = Dir.mkdir(File.join(File.dirname(__FILE__) + "/../../features/",dir_add_on))
    File.dirname(__FILE__) + "/../../features/"+dir_add_on
  end

  def build_nokogiri_from_cuke_sniffer_results
    file_name = File.join(File.dirname(__FILE__),'..','..','cuke_sniffer_results.html')
    file = File.open(file_name)
    doc = Nokogiri::HTML(file)
    file.close
    doc
  end

  def delete_cuke_sniffer_html_and_temp_dir(temp_dir)
    File.delete(File.join(File.dirname(__FILE__),'..','..','cuke_sniffer_results.html'))
    Dir.delete(temp_dir)
  end

  def cleanup_file_and_html(file_name)
    File.delete(File.join(File.dirname(__FILE__),'..','..','cuke_sniffer_results.html'))
    File.delete( file_name)
  end

  describe "XML output" do
    before(:each) do
      @file_name = "my_xml.xml"
    end

    after(:each) do
      File.delete(@file_name) if File.exist?(@file_name)
    end

    it "should generate a well formed xml of the content by respectable sections" do
      cuke_sniffer = CukeSniffer::CLI.new({:features_location=>@features_location, :step_definitions_location=> @step_definitions_location})
      cuke_sniffer.output_xml(@file_name)
      File.exists?(@file_name).should == true
    end
  end
end




