require 'erb'
require 'roxml'

module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Mixins: CukeSniffer::Constants, ROXML
  class CLI
    include CukeSniffer::Constants
    include CukeSniffer::RuleConfig
    include ROXML

    xml_name "cuke_sniffer"
    xml_accessor :rules, :as => [Rule], :in => "rules"
    xml_accessor :features_summary, :as => CukeSniffer::SummaryNode
    xml_accessor :scenarios_summary, :as => CukeSniffer::SummaryNode
    xml_accessor :step_definitions_summary, :as => CukeSniffer::SummaryNode
    xml_accessor :hooks_summary, :as => CukeSniffer::SummaryNode
    xml_accessor :improvement_list, :as => {:key => "rule", :value => "total"}, :in => "improvement_list", :from => "improvement"
    xml_accessor :features, :as => [CukeSniffer::Feature], :in => "features"
    xml_accessor :step_definitions, :as => [CukeSniffer::StepDefinition], :in => "step_definitions"
    xml_accessor :hooks, :as => [CukeSniffer::Hook], :in => "hooks"


    # Feature array: All Features gathered from the specified folder
    attr_accessor :features

    # StepDefinition Array: All StepDefinitions objects gathered from the specified folder
    attr_accessor :step_definitions

    # Hash: Summary objects and improvement lists
    # * Key: symbol, :total_score, :features, :step_definitions, :improvement_list
    # * Value: hash or array
    attr_accessor :summary

    # string: Location of the feature file or root folder that was searched in
    attr_accessor :features_location

    # string: Location of the step definition file or root folder that was searched in
    attr_accessor :step_definitions_location

    # string: Location of the hook file or root folder that was searched in
    attr_accessor :hooks_location

    # Scenario array: All Scenarios found in the features from the specified folder
    attr_accessor :scenarios

    # Hook array: All Hooks found in the current directory
    attr_accessor :hooks

    # Rules hash: All the rules that exist at runtime and their corresponding data
    attr_accessor :rules


    # Does analysis against the passed features and step definition locations
    #
    # Can be called in several ways.
    #
    #
    # No argument(assumes current directory is the project)
    #  cuke_sniffer = CukeSniffer::CLI.new
    #
    # Against single files
    #  cuke_sniffer = CukeSniffer::CLI.new({:features_location =>"my_feature.feature"})
    # Or
    #  cuke_sniffer = CukeSniffer::CLI.new({:step_definitions_location =>"my_steps.rb"})
    # Or
    #  cuke_sniffer = CukeSniffer::CLI.new({:hooks_location =>"my_hooks.rb"})
    #
    #
    # Against folders
    #  cuke_sniffer = CukeSniffer::CLI.new({:features_location =>"my_features_directory\", :step_definitions_location =>"my_steps_directory\"})
    #
    # You can mix and match all of the above examples
    #
    # Displays the sequence and a . indicator for each new loop in that process.
    # Handles creation of all Feature and StepDefinition objects
    # Then catalogs all step definition calls to be used for rules and identification
    # of dead steps.
    def initialize(parameters = {})
      initialize_rule_targets(parameters)
      evaluate_rules
      catalog_step_calls
      assess_score
    end

    # Returns the status of the overall project based on a comparison of the score to the threshold score
    def good?
      @summary[:total_score] <= Constants::THRESHOLDS["Project"]
    end

    # Calculates the score to threshold percentage of an object
    # Return: Float
    def problem_percentage
      @summary[:total_score].to_f / Constants::THRESHOLDS["Project"].to_f
    end

    # Prints out a summary of the results and the list of improvements to be made
    def output_results
      CukeSniffer::Formatter.output_console(self)
    end

    # Creates a html file with the collected project details
    # file_name defaults to "cuke_sniffer_results.html" unless specified
    # Second parameter used for passing into the markup.
    #  cuke_sniffer.output_html
    # Or
    #  cuke_sniffer.output_html("results01-01-0001.html")
    def output_html(file_name = DEFAULT_OUTPUT_FILE_NAME + ".html")
      CukeSniffer::Formatter.output_html(self, file_name)
    end

    # Creates a html file with minimum information: Summary, Rules, Improvement List.
    # file_name defaults to "cuke_sniffer_results.html" unless specified
    # Second parameter used for passing into the markup.
    #  cuke_sniffer.output_min_html
    # Or
    #  cuke_sniffer.output_min_html("results01-01-0001.html")
    def output_min_html(file_name = DEFAULT_OUTPUT_FILE_NAME + ".html")
      CukeSniffer::Formatter.output_min_html(self, file_name)
    end

    # Creates a xml file with the collected project details
    # file_name defaults to "cuke_sniffer.xml" unless specified
    #  cuke_sniffer.output_xml
    # Or
    #  cuke_sniffer.output_xml("cuke_sniffer01-01-0001.xml")
    def output_xml(file_name = DEFAULT_OUTPUT_FILE_NAME + ".xml")
      CukeSniffer::Formatter.output_xml(self, file_name)
    end

    # Gathers all StepDefinitions that have no calls
    # Returns a hash that has two different types of records
    # 1: String of the file with a dead step with an array of the line and regex of each dead step
    # 2: Symbol of :total with an integer that is the total number of dead steps
    def get_dead_steps
      CukeSniffer::DeadStepsHelper::build_dead_steps_hash(@step_definitions)
    end

    # Determines all normal and nested step calls and assigns them to the corresponding step definition.
    # Does direct and fuzzy matching
    def catalog_step_calls
      puts "\nCataloging Step Calls: "
      steps = CukeSniffer::CukeSnifferHelper.get_all_steps(@features, @step_definitions)
      @step_definitions.each do |step_definition|
        print '.'
        calls = steps.find_all { |location, step| step.gsub(STEP_STYLES, "") =~ step_definition.regex }
        calls.each { |call| step_definition.add_call(call[0], call[1].gsub(STEP_STYLES, "")) }
      end

      steps_with_expressions = CukeSniffer::CukeSnifferHelper.get_steps_with_expressions(steps)
      converted_steps = CukeSniffer::CukeSnifferHelper.convert_steps_with_expressions(steps_with_expressions)
      CukeSniffer::CukeSnifferHelper.catalog_possible_dead_steps(@step_definitions, converted_steps)
    end

    private

    def initialize_rule_targets(parameters)
      initialize_locations(parameters)
      initialize_feature_objects

      puts("\nStep Definitions: ")
      @step_definitions = build_objects_for_extension_from_location(@step_definitions_location, "rb") { |location| build_step_definitions(location) }

      puts("\nHooks:")
      @hooks = build_objects_for_extension_from_location(@hooks_location, "rb") { |location| build_hooks(location) }
    end

    def initialize_locations(parameters)
      @features_location = parameters[:features_location] ? parameters[:features_location] : Dir.getwd
      @step_definitions_location = parameters[:step_definitions_location] ? parameters[:step_definitions_location] : Dir.getwd
      @hooks_location = parameters[:hooks_location] ? parameters[:hooks_location] : Dir.getwd
    end

    def initialize_feature_objects
      puts "\nFeatures:"
      @features = build_objects_for_extension_from_location(features_location, "feature") { |location| CukeSniffer::Feature.new(location) }
      @scenarios = CukeSniffer::CukeSnifferHelper.get_all_scenarios(@features)
    end

    def evaluate_rules
      @rules = CukeSniffer::CukeSnifferHelper.build_rules(RULES)
      CukeSniffer::RulesEvaluator.new(self, @rules)
    end

    def initialize_summary
      @summary = {
          :total_score => 0,
          :improvement_list => {}
      }
    end

    def assess_score
      puts "\nAssessing Score: "
      initialize_summary
      summarize(:features, @features, "Feature", @features_summary)
      summarize(:scenarios, @scenarios, "Scenario", @scenarios_summary)
      summarize(:step_definitions, @step_definitions, "StepDefinition", @step_definitions_summary)
      summarize(:hooks, @hooks, "Hook", @hooks_summary)
      @summary[:improvement_list] = CukeSniffer::SummaryHelper.sort_improvement_list(@summary[:improvement_list])
      @improvement_list = @summary[:improvement_list]
    end

    def summarize(symbol, list, name, summary_object)
      @summary[symbol] = CukeSniffer::SummaryHelper.assess_rule_target_list(list, name)
      @summary[:total_score] = @summary[symbol][:total_score]
      @summary[symbol][:improvement_list].each do |phrase, count|
        @summary[:improvement_list][phrase] ||= 0
        @summary[:improvement_list][phrase] += @summary[symbol][:improvement_list][phrase]
      end
      summary_object = CukeSniffer::SummaryHelper::load_summary_data(@summary[symbol])
    end

    def build_step_definitions(file_name)
      build_object_for_extension_from_file(file_name, STEP_DEFINITION_REGEX, CukeSniffer::StepDefinition)
    end

    def build_hooks(file_name)
      build_object_for_extension_from_file(file_name, HOOK_REGEX, CukeSniffer::Hook)
    end

    def build_file_list_for_extension_from_location(pattern_location, extension)
      list = []
      unless pattern_location.nil?
        if File.file?(pattern_location)
          [pattern_location]
        else
          Dir["#{pattern_location}/**/*.#{extension}"]
        end
      end
    end

    def build_objects_for_extension_from_location(pattern_location, extension, &block)
      file_list = build_file_list_for_extension_from_location(pattern_location, extension)
      list = []
      file_list.each {|file_name| list << block.call(file_name) }
      list.flatten
    end


    def build_object_for_extension_from_file(file_name, regex, cuke_sniffer_class)
      file_lines = IO.readlines(file_name)

      counter = 0
      code = []
      object_list = []
      found_first_object = false
      until counter >= file_lines.length
        if file_lines[counter] =~ regex and !code.empty? and found_first_object
          location = "#{file_name}:#{counter+1 - code.count}"
          object_list << cuke_sniffer_class.new(location, code)
          code = []
        end
        found_first_object = true if file_lines[counter] =~ regex
        code << file_lines[counter].strip
        counter+=1
      end
      location = "#{file_name}:#{counter+1 -code.count}"
      object_list << cuke_sniffer_class.new(location, code) unless code.empty? or !found_first_object
      object_list
    end

  end
end
