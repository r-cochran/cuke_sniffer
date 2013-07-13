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
  before(:each) do
    @cli = CukeSniffer::CLI.new()
  end

  it "should punish Hooks without content" do
    raw_code = ["Before do",
                "end"]
    @cli.hooks = [CukeSniffer::Hook.new("location.rb:1", raw_code)]
    rule = CukeSniffer::CLI.build_rule(RULES[:empty_hook])
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.hooks[0], rule)
  end

  it "should punish hooks that exist outside of the hooks.rb file" do
    raw_code = ["Before do",
                "end"]
    @cli.hooks = [CukeSniffer::Hook.new("location.rb:1", raw_code)]
    rule = CukeSniffer::CLI.build_rule(RULES[:hook_not_in_hooks_file])
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.hooks[0], rule)
  end

  it "should punish Around hooks that do not have 2 parameters. 0 parameters." do
    raw_code = ["Around do",
                "end"]
    @cli.hooks = [CukeSniffer::Hook.new("location.rb:1", raw_code)]
    rule = CukeSniffer::CLI.build_rule(RULES[:around_hook_without_2_parameters])
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.hooks[0], rule)
  end

  it "should punish Around hooks that do not have 2 parameters. 1 parameter." do
    raw_code = ["Around do |a|",
                "end"]
    @cli.hooks = [CukeSniffer::Hook.new("location.rb:1", raw_code)]
    rule = CukeSniffer::CLI.build_rule(RULES[:around_hook_without_2_parameters])
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.hooks[0], rule)
  end

  it "should punish Around hooks that do not have 2 parameters. 3 parameters." do
    raw_code = ["Around do |a, b, c|",
                "end"]
    @cli.hooks = [CukeSniffer::Hook.new("location.rb:1", raw_code)]
    rule = CukeSniffer::CLI.build_rule(RULES[:around_hook_without_2_parameters])
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.hooks[0], rule)
  end

  it "should punish Around hooks that never have a call on their 2nd parameter. The scenario is not called." do
    raw_code = ["Around do |scenario, block|",
                "end"]
    @cli.hooks = [CukeSniffer::Hook.new("location.rb:1", raw_code)]
    rule = CukeSniffer::CLI.build_rule(RULES[:around_hook_no_block_call])
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.hooks[0], rule)
  end

  it "should punish hooks without a begin/rescue for debugging." do
    raw_code = ["Before do",
                "# code",
                "end"]
    @cli.hooks = [CukeSniffer::Hook.new("location.rb:1", raw_code)]
    rule = CukeSniffer::CLI.build_rule(RULES[:hook_no_debugging])
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.hooks[0], rule)
  end

  it "should not punish hooks for a begin/rescue for debugging when there is no code." do
    raw_code = ["Before do",
                "end"]
    hook = CukeSniffer::Hook.new("location.rb:1", raw_code)
    @cli.hooks = [CukeSniffer::Hook.new("location.rb:1", raw_code)]
    rule = CukeSniffer::CLI.build_rule(RULES[:hook_no_debugging])
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    hook.rules_hash.include?(RULES[:hook_no_debugging][:phrase]).should be_false
  end

  it "should punish hooks that are all comments" do
    raw_code = ["Before do",
                "# comment",
                "# comment",
                "end"]
    @cli.hooks = [CukeSniffer::Hook.new("location.rb:1", raw_code)]
    rule = CukeSniffer::CLI.build_rule(RULES[:hook_all_comments])
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.hooks[0], rule)
  end

  it "should punish hooks with negated tags on and'd tags" do
    raw_code = ["Before('@tag', '~@tag') do",
                "end"]
    @cli.hooks = [CukeSniffer::Hook.new("location.rb:1", raw_code)]
    rule = CukeSniffer::CLI.build_rule(RULES[:hook_conflicting_tags])
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.hooks[0], rule)
  end

  it "should punish hooks with negated tags on or'd tags" do
    raw_code = ["Before('@tag,~@tag') do",
                "end"]
    @cli.hooks = [CukeSniffer::Hook.new("location.rb:1", raw_code)]
    rule = CukeSniffer::CLI.build_rule(RULES[:hook_conflicting_tags])
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.hooks[0], rule)
  end

  it "should punish hooks with duplicate tags" do
    raw_code = ["Before('@tag,@tag') do",
                "end"]
    @cli.hooks = [CukeSniffer::Hook.new("location.rb:1", raw_code)]
    rule = CukeSniffer::CLI.build_rule(RULES[:hook_duplicate_tags])
    CukeSniffer::RulesEvaluator.new(@cli, [rule])
    verify_rule(@cli.hooks[0], rule)
  end

end