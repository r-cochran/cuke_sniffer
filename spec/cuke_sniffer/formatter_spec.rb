require 'spec_helper'

describe CukeSniffer::Formatter do
  before(:each) do
    @file_name = "my_html.html"
  end

  after(:each) do
    delete_temp_files
  end

  describe "sorting cucumber objects by score" do

    it "should order the features in descending order by score." do
      @file_name = "my_feature.feature"
      build_file(["Feature: I am a feature"], @file_name)

      cuke_sniffer = CukeSniffer::CLI.new()

      big_feature = CukeSniffer::Feature.new(@file_name)
      big_feature.total_score = 20

      little_feature = CukeSniffer::Feature.new(@file_name)
      little_feature.total_score = big_feature.total_score - 1

      cuke_sniffer.features = [little_feature, big_feature]
      cuke_sniffer = CukeSniffer::Formatter.sort_cuke_sniffer_lists(cuke_sniffer)

      cuke_sniffer.features.should == [big_feature, little_feature]
    end

    it "should order the step definitions in descending order by score." do
      step_def_raw_code = ["When /^the second number is 1$/ do",
                           "@second_number = 1",
                           "end"]
      step_def_location = "my_steps.rb:1"

      cuke_sniffer = CukeSniffer::CLI.new()

      big_step = CukeSniffer::StepDefinition.new(step_def_location, step_def_raw_code)
      big_step.score = 10

      little_step = CukeSniffer::StepDefinition.new(step_def_location, step_def_raw_code)
      little_step.score = big_step.score - 1

      cuke_sniffer.step_definitions = [little_step, big_step]
      cuke_sniffer = CukeSniffer::Formatter.sort_cuke_sniffer_lists(cuke_sniffer)

      cuke_sniffer.step_definitions.should == [big_step, little_step]
    end

    it "should order the hooks in descending order by score." do
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

      cuke_sniffer = CukeSniffer::Formatter.sort_cuke_sniffer_lists(cuke_sniffer)
      cuke_sniffer.hooks.should == [big_hook, little_hook]
    end

    it "should order the rules in descending order by score." do
      cuke_sniffer = CukeSniffer::CLI.new()

      big_rule = CukeSniffer::Rule.new()
      big_rule.score = 100

      little_rule = CukeSniffer::Rule.new()
      little_rule.score = big_rule.score - 1

      cuke_sniffer.rules = [little_rule, big_rule]

      cuke_sniffer = CukeSniffer::Formatter.sort_cuke_sniffer_lists(cuke_sniffer)

      cuke_sniffer.rules.should == [big_rule, little_rule]
    end

  end

  describe "creating console output" do
    it "should print a concise summary of the project to the console" do
      @file_name = 'test_output'
      file_output = File.new( @file_name, 'w' )
      $stdout = file_output
      cuke_sniffer = CukeSniffer::CLI.new()
      CukeSniffer::Formatter.output_console(cuke_sniffer)
      $stdout = STDOUT
      file_output.close
      File.exists?(@file_name).should be_true
    end
  end

  describe "creating html output" do
    def create_html_report_for_empty_type(type_location, location_name)
      Dir.delete(location_name) if Dir.exists?(location_name)
      Dir.mkdir(location_name)
      cuke_sniffer = CukeSniffer::CLI.new({type_location => location_name})
      CukeSniffer::Formatter.output_html(cuke_sniffer)
      Dir.delete(location_name)
    end

    def build_nokogiri_from_cuke_sniffer_results
      file_name = CukeSniffer::Constants::DEFAULT_OUTPUT_FILE_NAME + ".html"
      file = File.open(file_name)
      doc = Nokogiri::HTML(file)
      file.close
      doc
    end

    it "should generate an html report." do
      cuke_sniffer = CukeSniffer::CLI.new()
      CukeSniffer::Formatter.output_html(cuke_sniffer, @file_name)
      File.exists?(@file_name).should == true
    end

    it "should append .html to the end of passed file name if it does not have the extension." do
      cuke_sniffer = CukeSniffer::CLI.new()
      CukeSniffer::Formatter.output_html(cuke_sniffer, "my_html")
      File.exists?("my_html.html").should be_true
    end

    it "should have a minimum output mode where only cuke_sniffer details are present." do
      cuke_sniffer = CukeSniffer::CLI.new()
      CukeSniffer::Formatter.output_min_html(cuke_sniffer, @file_name)
      File.exists?(@file_name).should == true
    end

    describe "messages for when no object of a type was found" do

      it "should say that there were no features to sniff when no features were found." do
        features_location = "temp"
        create_html_report_for_empty_type(:features_location, features_location)
        expected_message = "There were no Features to sniff in '#{features_location}'!"
        xpath = "//div[@id = 'features_data']/div[@class = 'empty_set_message']"
        build_nokogiri_from_cuke_sniffer_results.xpath(xpath).text.should == expected_message
      end

      it "should say that there were no features to sniff when no step definitions were found." do
        step_definitions_location = "temp"
        create_html_report_for_empty_type(:step_definitions_location, step_definitions_location)
        expected_message = "There were no Step Definitions to sniff in '#{step_definitions_location}'!"
        xpath = '//*[@id="step_definitions_data"]/div'
        build_nokogiri_from_cuke_sniffer_results.xpath(xpath).text.should == expected_message
      end

      it "should say that there were no features to sniff when no hooks were found." do
        hooks_location = "temp"
        create_html_report_for_empty_type(:hooks_location, hooks_location)
        expected_message = "There were no Hooks to sniff in '#{hooks_location}'!"
        xpath = '//*[@id="hooks_data"]/div'
        build_nokogiri_from_cuke_sniffer_results.xpath(xpath).text.should == expected_message
      end

    end

    describe "messages for when no smells were found for an object" do

      it "produces a no smells found message when there are no rule violations for features" do
        feature_block = [
            "Feature: Complex Calculator",
            "Scenario: Add two numbers",
            "Given the first number is one",
            "And the second number is one",
            "When the calculator adds",
            "Then the result is two"
        ]
        @file_name = "my_feature.feature"
        build_file(feature_block, @file_name)

        cuke_sniffer = CukeSniffer::CLI.new({:features_location => @file_name})
        CukeSniffer::Formatter.output_html(cuke_sniffer)

        expected_message = "Excellent! No smells found for Features and Scenarios!"
        xpath = "//div[@id = 'features_data']/div[@class = 'empty_set_message']"
        build_nokogiri_from_cuke_sniffer_results.xpath(xpath).text.should == expected_message
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
        @file_name = "my_definition_steps.rb"
        build_file(step_definitions_block, @file_name)

        cuke_sniffer = CukeSniffer::CLI.new({:step_definitions_location => @file_name})
        CukeSniffer::Formatter.output_html(cuke_sniffer)

        expected_message = "Excellent! No smells found for Step Definitions!"
        xpath = "//div[@id = 'step_definitions_data']/div[@class = 'empty_set_message']"
        build_nokogiri_from_cuke_sniffer_results.xpath(xpath).text.should == expected_message
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

        @file_name = "my_hooks.rb"
        build_file(hook_block, @file_name)

        cuke_sniffer = CukeSniffer::CLI.new({:hooks_location => @file_name})
        CukeSniffer::Formatter.output_html(cuke_sniffer)

        expected_message = "Excellent! No smells found for Hooks!"
        xpath = "//div[@id = 'hooks_data']/div[@class = 'empty_set_message']"
        build_nokogiri_from_cuke_sniffer_results.xpath(xpath).text.should == expected_message
      end
    end

  end

  describe "creating xml output" do
    before(:each) do
      @file_name = "my_xml.xml"
    end

    it "should generate a well formed xml of the content by respectable sections" do
      cuke_sniffer = CukeSniffer::CLI.new()
      CukeSniffer::Formatter.output_xml(cuke_sniffer, @file_name)
      File.exists?(@file_name).should == true
    end

    it "should append .xml to the end of passed file name if it does have an extension already" do
      cuke_sniffer = CukeSniffer::CLI.new()
      CukeSniffer::Formatter.output_xml(cuke_sniffer, "my_xml")
      File.exists?("my_xml.xml").should be_true
    end

  end

end