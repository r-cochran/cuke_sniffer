require 'spec_helper'
require 'cuke_sniffer/results_builder'

describe CukeSniffer::ResultsBuilder do
  describe 'build rules'do
    it "returns an empty array when there is no rules" do
      CukeSniffer::ResultsBuilder.new().build_rules(nil).should == []
    end
  end
end
