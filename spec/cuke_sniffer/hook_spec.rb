require 'spec_helper'

describe CukeSniffer::Hook do

  it "should break down the content of a hook and store it" do
    raw_code = ["AfterConfiguration do",
                "1+1",
                "end"]
    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    hook.type.should == "AfterConfiguration"
    hook.code.should == ["1+1"]
    hook.tags.should == []
    hook.location.should == "location.rb:1"
    hook.parameters.should == []
  end

  it "should parse the tag filter of a hook correctly and store it" do
    raw_code = ["Before(\"@tag1\", '@tag2,@tag3', '~@tag4') do",
                "end"]
    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    hook.type.should == "Before"
    hook.code.should == []
    hook.tags.should == ["@tag1", "@tag2,@tag3", "~@tag4"]
    hook.location.should == "location.rb:1"
    hook.parameters.should == []
  end

  it "should parse the parameters of a hook correctly and store it" do
    raw_code = ["Before do |scenario, block|",
                "end"]
    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    hook.parameters.should == ["scenario", "block"]
  end
end

describe "HookRules" do
  def validate_rule(scenario, rule)
    phrase = rule[:phrase]

    scenario.rules_hash.include?(phrase).should be_true
    scenario.rules_hash[phrase].should > 0
    scenario.score.should >= rule[:score]
  end

  it "should punish Hooks without content" do
    raw_code = ["Before do",
                "end"]
    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    validate_rule(hook, RULES[:empty_hook])
  end

  it "should punish hooks that exist outside of the hooks.rb file" do
    raw_code = ["Before do",
                "end"]
    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    validate_rule(hook, RULES[:hook_not_in_hooks_file])
  end

  it "should punish Around hooks that do not have 2 parameters. 0 parameters." do
    raw_code = ["Around do",
                "end"]
    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    validate_rule(hook, RULES[:around_hook_without_2_parameters])
  end

  it "should punish Around hooks that do not have 2 parameters. 1 parameter." do
    raw_code = ["Around do |a|",
                "end"]
    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    validate_rule(hook, RULES[:around_hook_without_2_parameters])
  end

  it "should punish Around hooks that do not have 2 parameters. 3 parameters." do
    raw_code = ["Around do |a, b, c|",
                "end"]
    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    validate_rule(hook, RULES[:around_hook_without_2_parameters])
  end

  it "should punish Around hooks that never have a call on their 2nd parameter. The scenario is not called." do
    raw_code = ["Around do |scenario, block|",
                "end"]
    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    validate_rule(hook, RULES[:around_hook_no_block_call])
  end

  it "should punish hooks without a begin/rescue for debugging." do
    raw_code = ["Before do",
                "end"]
    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    validate_rule(hook, RULES[:hook_no_debugging])
  end

  it "should punish hooks that are all comments" do
    raw_code = ["Before do",
                "# comment",
                "# comment",
                "end"]
    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    validate_rule(hook, RULES[:hook_all_comments])
  end

  it "should punish hooks with negated tags on and'd tags" do
    raw_code = ["Before('@tag', '~@tag') do",
                "end"]
    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    validate_rule(hook, RULES[:hook_conflicting_tags])
  end

  it "should punish hooks with negated tags on or'd tags" do
    raw_code = ["Before('@tag,~@tag') do",
                "end"]

    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    validate_rule(hook, RULES[:hook_conflicting_tags])
  end

  it "should punish hooks with duplicate tags" do
    raw_code = ["Before('@tag,@tag') do",
                "end"]

    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    validate_rule(hook, RULES[:hook_duplicate_tags])
  end

end