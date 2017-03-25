require 'spec_helper'
require 'cuke_sniffer/cuke_sniffer_helper'

describe CukeSniffer::CukeSnifferHelper do

  it "should not include universal nested step calls when extracting nested step definitions" do
    step_definition_block = [
        "Given /^step nested step call$/ do",
        "  steps %{And \#{variable_step_name}}",
        "end"
    ]

    step_definition = CukeSniffer::StepDefinition.new("location.rb:1", step_definition_block)
    found_nested_steps = CukeSniffer::CukeSnifferHelper.convert_steps_with_expressions(step_definition.nested_steps)
    expect(found_nested_steps.empty?).to be true
  end


end