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