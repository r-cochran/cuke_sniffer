require 'spec_helper'
require 'cuke_sniffer/summary_helper'

describe CukeSniffer::SummaryHelper do

  it "should sort an improvement list on the number of times a rule fires." do
    expected_sorted_improvement_list = {
        "top rule" => 3,
        "middle rule" => 2,
        "bottom rule" => 1
    }
    improvement_list = {
        "middle rule" => 2,
        "bottom rule" => 1,
        "top rule" => 3
    }
    actual_sorted_improvement_list = CukeSniffer::SummaryHelper.sort_improvement_list(improvement_list)
    actual_sorted_improvement_list.keys.should == expected_sorted_improvement_list.keys
  end

  describe "summarizing a list of rule target objects" do

    it "should have a default template for a summary" do
      expected_template_keys = [:total, :total_score, :min, :min_file, :max, :max_file, :average, :threshold, :good, :bad, :improvement_list]
      CukeSniffer::SummaryHelper::make_assessment_hash.keys.should == expected_template_keys
    end

    describe "initializing the summary for static values from the rule target list" do

      it "should initialize the total number of rule targets to the size of the list" do
        scenario_block = ["Scenario: testing"]
        scenario = CukeSniffer::Scenario.new("location.rb:1", scenario_block)
        initialized_assessment_hash = CukeSniffer::SummaryHelper::initialize_assessment_hash([scenario], "Scenario")
        initialized_assessment_hash[:total].should == 1
      end

      it "should initialize the threshold of rule targets to the constant value for the type" do
        scenario_block = ["Scenario: testing"]
        scenario = CukeSniffer::Scenario.new("location.rb:1", scenario_block)
        initialized_assessment_hash = CukeSniffer::SummaryHelper::initialize_assessment_hash([scenario], "Scenario")
        initialized_assessment_hash[:threshold].should == THRESHOLDS["Scenario"]
      end

      it "should not initialize the min, min_file, max, max_file for an empty list" do
        initialized_assessment_hash = CukeSniffer::SummaryHelper::initialize_assessment_hash([], "Scenario")
        initialized_assessment_hash[:min].nil?.should be_true
        initialized_assessment_hash[:min_file].nil?.should be_true
        initialized_assessment_hash[:max].nil?.should be_true
        initialized_assessment_hash[:max_file].nil?.should be_true
      end

    end

    it "should build up a hash with details on a list of any rule target object" do
      scenario_block = [
          "Scenario: My scenario",
          "Given I am a scenario"
      ]
      scenario = CukeSniffer::Scenario.new("location.rb:1", scenario_block)
      scenario.rules_hash = {"my_rule" => 3}
      scenario.score = 20

      scenario_list = [scenario]

      actual_result_hash = CukeSniffer::SummaryHelper.assess_rule_target_list(scenario_list, "Scenario")
      actual_result_hash.empty?.should be_false

    end

    it "should keep track of the total number objects in the list" do
      scenario_block = [
          "Scenario: My scenario",
          "Given I am a scenario"
      ]
      scenario = CukeSniffer::Scenario.new("location.rb:1", scenario_block)
      scenario_list = [scenario, scenario]
      actual_result_hash = CukeSniffer::SummaryHelper.assess_rule_target_list(scenario_list, "Scenario")
      actual_result_hash[:total].should == 2
    end

    it "should keep track of the total score across the objects" do
      scenario_block = [
          "Scenario: My scenario",
          "Given I am a scenario"
      ]
      scenario = CukeSniffer::Scenario.new("location.rb:1", scenario_block)
      score = rand(1000)
      scenario.score = score
      scenario_list = [scenario, scenario]
      actual_result_hash = CukeSniffer::SummaryHelper.assess_rule_target_list(scenario_list, "Scenario")
      actual_result_hash[:total_score].should == score + score
    end

    it "should keep track of the lowest score out of the objects" do
      scenario_block = [
          "Scenario: My scenario",
          "Given I am a scenario"
      ]
      high_scenario = CukeSniffer::Scenario.new("location.rb:1", scenario_block)
      high_scenario.score = 100
      low_scenario = CukeSniffer::Scenario.new("lower_location.rb:1", scenario_block)
      low_scenario.score = 15
      scenario_list = [low_scenario, high_scenario]
      actual_result_hash = CukeSniffer::SummaryHelper.assess_rule_target_list(scenario_list, "Scenario")
      actual_result_hash[:min].should == 15
    end

    it "should keep track of the rule target object location with the lowest score" do
      scenario_block = [
          "Scenario: My scenario",
          "Given I am a scenario"
      ]
      high_scenario = CukeSniffer::Scenario.new("higher_location.rb:1", scenario_block)
      high_scenario.score = 100
      low_scenario = CukeSniffer::Scenario.new("lower_location.rb:1", scenario_block)
      low_scenario.score = 15
      scenario_list = [low_scenario, high_scenario]
      actual_result_hash = CukeSniffer::SummaryHelper.assess_rule_target_list(scenario_list, "Scenario")
      actual_result_hash[:min_file].should == "lower_location.rb:1"
    end

    it "should keep track of the highest score out of the objects" do
      scenario_block = [
          "Scenario: My scenario",
          "Given I am a scenario"
      ]
      high_scenario = CukeSniffer::Scenario.new("higher_location.rb:1", scenario_block)
      high_scenario.score = 100
      low_scenario = CukeSniffer::Scenario.new("lower_location.rb:1", scenario_block)
      low_scenario.score = 15
      scenario_list = [low_scenario, high_scenario]
      actual_result_hash = CukeSniffer::SummaryHelper.assess_rule_target_list(scenario_list, "Scenario")
      actual_result_hash[:max].should == 100
    end

    it "should keep track of the rule target object file with the highest score" do
      scenario_block = [
          "Scenario: My scenario",
          "Given I am a scenario"
      ]
      high_scenario = CukeSniffer::Scenario.new("higher_location.rb:1", scenario_block)
      high_scenario.score = 100
      low_scenario = CukeSniffer::Scenario.new("lower_location.rb:1", scenario_block)
      low_scenario.score = 15
      scenario_list = [low_scenario, high_scenario]
      actual_result_hash = CukeSniffer::SummaryHelper.assess_rule_target_list(scenario_list, "Scenario")
      actual_result_hash[:max_file].should == "higher_location.rb:1"
    end

    it "should keep track of the average score (rounded to 2 decimal places) across all of the rule target objects" do
      scenario_block = [
          "Scenario: My scenario",
          "Given I am a scenario"
      ]
      high_scenario = CukeSniffer::Scenario.new("higher_location.rb:1", scenario_block)
      high_scenario.score = 100
      low_scenario = CukeSniffer::Scenario.new("lower_location.rb:1", scenario_block)
      low_scenario.score = 15
      scenario_list = [low_scenario, high_scenario]
      actual_result_hash = CukeSniffer::SummaryHelper.assess_rule_target_list(scenario_list, "Scenario")
      actual_result_hash[:average].should == ((high_scenario.score + low_scenario.score).to_f / 2).round(2)
    end

    it "should keep track of the threshold set for a rule object" do
      actual_result_hash = CukeSniffer::SummaryHelper.assess_rule_target_list([], "Scenario")
      actual_result_hash[:threshold].should == THRESHOLDS["Scenario"]
    end

    it "should keep track of the number of rule target objects that were above the threshold (bad)." do
      scenario_block = [
          "Scenario: My scenario",
          "Given I am a scenario"
      ]
      high_scenario = CukeSniffer::Scenario.new("higher_location.rb:1", scenario_block)
      high_scenario.score = THRESHOLDS["Scenario"] + 1
      low_scenario = CukeSniffer::Scenario.new("lower_location.rb:1", scenario_block)
      low_scenario.score = THRESHOLDS["Scenario"] - 1
      scenario_list = [low_scenario, high_scenario]
      actual_result_hash = CukeSniffer::SummaryHelper.assess_rule_target_list(scenario_list, "Scenario")
      actual_result_hash[:bad].should == 1
    end

    it "should keep track of the number of rule target objects that were below the threshold (good)." do
      scenario_block = [
          "Scenario: My scenario",
          "Given I am a scenario"
      ]
      high_scenario = CukeSniffer::Scenario.new("higher_location.rb:1", scenario_block)
      high_scenario.score = THRESHOLDS["Scenario"] + 1
      low_scenario = CukeSniffer::Scenario.new("lower_location.rb:1", scenario_block)
      low_scenario.score = THRESHOLDS["Scenario"] - 1
      scenario_list = [low_scenario, high_scenario]
      actual_result_hash = CukeSniffer::SummaryHelper.assess_rule_target_list(scenario_list, "Scenario")
      actual_result_hash[:good].should == 1
    end

    it "should keep a list of all improvements that need to be mad across the rule target objects" do
      scenario_block = [
          "Scenario: My scenario",
          "Given I am a scenario"
      ]
      high_scenario = CukeSniffer::Scenario.new("higher_location.rb:1", scenario_block)
      high_scenario.rules_hash = {"high rule" => 1, "shared rule" => 1}
      low_scenario = CukeSniffer::Scenario.new("lower_location.rb:1", scenario_block)
      low_scenario.rules_hash = {"low rule" => 1, "shared rule" => 1}
      scenario_list = [low_scenario, high_scenario]
      actual_result_hash = CukeSniffer::SummaryHelper.assess_rule_target_list(scenario_list, "Scenario")
      actual_result_hash[:improvement_list].should == {"high rule" => 1, "low rule" => 1, "shared rule" => 2}
    end
  end

end