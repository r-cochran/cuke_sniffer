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
    #  cuke_sniffer = CukeSniffer::CLI.new("my_feature.feature", nil)
    # Or
    #  cuke_sniffer = CukeSniffer::CLI.new(nil, "my_steps.rb")
    #
    #
    # Against folders
    #  cuke_sniffer = CukeSniffer::CLI.new("my_features_directory\", "my_steps_directory\")
    #
    # You can mix and match all of the above examples
    #
    # Displays the sequence and a . indicator for each new loop in that process.
    # Handles creation of all Feature and StepDefinition objects
    # Then catalogs all step definition calls to be used for rules and identification
    # of dead steps.
    def initialize(features_location = Dir.getwd, step_definitions_location = Dir.getwd, hooks_location = Dir.getwd)
      @features_location = features_location
      @step_definitions_location = step_definitions_location
      @hooks_location = hooks_location
      @features = []
      @scenarios = []
      @step_definitions = []
      @hooks = []
      @rules = []

      puts "\nFeatures:"
      #extract this to a method that accepts a block and yields for the build pattern
      unless features_location.nil?
        if File.file?(features_location)
          @features = [CukeSniffer::Feature.new(features_location)]
        else
          build_file_list_from_folder(features_location, ".feature").each { |location|
            @features << CukeSniffer::Feature.new(location)
            print '.'
          }
        end
      end

      @scenarios = get_all_scenarios(@features)

      puts("\nStep Definitions:")
      unless step_definitions_location.nil?
        if File.file?(step_definitions_location)
          @step_definitions = [build_step_definitions(step_definitions_location)]
        else
          build_file_list_from_folder(step_definitions_location, ".rb").each { |location|
            @step_definitions << build_step_definitions(location)
            print '.'
          }
        end
      end
      @step_definitions.flatten!

      puts("\nHooks:")
      unless hooks_location.nil?
        if File.file?(hooks_location)
          @hooks = [build_hooks(hooks_location)]
        else
          build_file_list_from_folder(hooks_location, ".rb").each { |location|
            @hooks << build_hooks(location)
            print '.'
          }
        end
      end
      @hooks.flatten!

      @rules = CukeSniffer::CLI.build_rules(RULES)
      CukeSniffer::RulesEvaluator.new(self, @rules)
      @summary = {
          :total_score => 0,
          :features => {},
          :step_definitions => {},
          :hooks => {},
          :improvement_list => {}
      }
      puts "\nCataloging Step Calls: "
      catalog_step_calls
      puts "\nAssessing Score: "
      assess_score
      @improvement_list = @summary[:improvement_list]
      @features_summary = load_summary_data(@summary[:features])
      @scenarios_summary = load_summary_data(@summary[:scenarios])
      @step_definitions_summary = load_summary_data(@summary[:step_definitions])
      @hooks_summary = load_summary_data(@summary[:hooks])
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
      feature_results = @summary[:features]
      scenario_results = @summary[:scenarios]
      step_definition_results = @summary[:step_definitions]
      hooks_results = @summary[:hooks]
      output = "Suite Summary
  Total Score: #{@summary[:total_score]}
    Features
      Min: #{feature_results[:min]} (#{feature_results[:min_file]})
      Max: #{feature_results[:max]} (#{feature_results[:max_file]})
      Average: #{feature_results[:average]}
    Scenarios
      Min: #{scenario_results[:min]} (#{scenario_results[:min_file]})
      Max: #{scenario_results[:max]} (#{scenario_results[:max_file]})
      Average: #{scenario_results[:average]}
    Step Definitions
      Min: #{step_definition_results[:min]} (#{step_definition_results[:min_file]})
      Max: #{step_definition_results[:max]} (#{step_definition_results[:max_file]})
      Average: #{step_definition_results[:average]}
    Hooks
      Min: #{hooks_results[:min]} (#{hooks_results[:min_file]})
      Max: #{hooks_results[:max]} (#{hooks_results[:max_file]})
      Average: #{hooks_results[:average]}
  Improvements to make:"
      create_improvement_list.each { |item| output << "\n    #{item}" }
      output
    end

    # Creates a html file with the collected project details
    # file_name defaults to "cuke_sniffer_results.html" unless specified
    # Second parameter used for passing into the markup.
    #  cuke_sniffer.output_html
    # Or
    #  cuke_sniffer.output_html("results01-01-0001.html")
    def output_html(file_name = "cuke_sniffer_results.html", cuke_sniffer = self, markup_source = File.join(File.dirname(__FILE__), 'report'))
      @features = @features.sort_by { |feature| feature.total_score }.reverse
      @step_definitions = @step_definitions.sort_by { |step_definition| step_definition.score }.reverse
      @hooks = @hooks.sort_by { |hook| hook.score }.reverse

      markup_erb = ERB.new extract_markup(markup_source)
      output = markup_erb.result(binding)
      File.open(file_name, 'w') do |f|
        f.write(output)
      end
    end

    # Creates a xml file with the collected project details
    # file_name defaults to "cuke_sniffer.xml" unless specified
    #  cuke_sniffer.output_xml
    # Or
    #  cuke_sniffer.output_xml("cuke_sniffer01-01-0001.xml")
    def output_xml(file_name = "cuke_sniffer.xml")
      doc = Nokogiri::XML::Document.new
      doc.root = self.to_xml
      open(file_name, "w") do |file|
        file << doc.serialize
      end
    end

    # Gathers all StepDefinitions that have no calls
    # Returns a hash that has two different types of records
    # 1: String of the file with a dead step with an array of the line and regex of each dead step
    # 2: Symbol of :total with an integer that is the total number of dead steps
    def get_dead_steps
      dead_steps_hash = {}
      @step_definitions.each do |step_definition|
        location_match = step_definition.location.match(/(?<file>.*).rb:(?<line>\d+)/)
        file_name = location_match[:file]
        regex = step_definition.regex.to_s.match(/\(\?\-mix\:(?<regex>.*)\)/)[:regex]
        dead_steps_hash[file_name] ||= []
        dead_steps_hash[file_name] << "#{location_match[:line]}: /#{regex}/" if step_definition.calls.empty?
      end
      total = 0
      dead_steps_hash.each_key do |key|
        unless dead_steps_hash[key] == []
          total += dead_steps_hash[key].size
          dead_steps_hash[key].sort_by! { |row| row[/^\d+/].to_i }
        else
          dead_steps_hash.delete(key)
        end
      end
      dead_steps_hash[:total] = total
      dead_steps_hash
    end

    # Determines all normal and nested step calls and assigns them to the corresponding step definition.
    # Does direct and fuzzy matching
    def catalog_step_calls
      steps = get_all_steps
      @step_definitions.each do |step_definition|
        print '.'
        calls = steps.find_all { |location, step| step.gsub(STEP_STYLES, "") =~ step_definition.regex }
        calls.each { |call| step_definition.add_call(call[0], call[1].gsub(STEP_STYLES, "")) }
      end

      converted_steps = convert_steps_with_expressions(get_steps_with_expressions(steps))
      catalog_possible_dead_steps(converted_steps)
    end


    def self.build_rules(rules)
      return [] if rules.nil?
      rules.collect do |key, value|
        build_rule(value)
      end
    end

    def self.build_rule(value)
      rule = CukeSniffer::Rule.new
      rule.phrase = value[:phrase]
      rule.score = value[:score]
      rule.enabled = value[:enabled]
      conditional_keys = value.keys - [:phrase, :score, :enabled, :targets, :reason]
      conditions = {}
      conditional_keys.each do |key|
        conditions[key] = value[key]
      end
      rule.conditions = conditions
      rule.reason = value[:reason]
      rule.targets = value[:targets]
      rule
    end


    private

    def extract_variables_from_example(example)
      example = example[example.index('|')..example.length]
      example.split(/\s*\|\s*/) - [""]
    end

    def assess_score
      @summary[:features] = assess_array(@features, "Feature")
      @summary[:scenarios] = assess_array(@scenarios, "Scenario")
      @summary[:step_definitions] = assess_array(@step_definitions, "StepDefinition")
      @summary[:hooks] = assess_array(@hooks, "Hook")
      sort_improvement_list
    end

    def get_all_steps
      feature_steps = extract_steps_from_features
      step_definition_steps = extract_steps_from_step_definitions
      feature_steps.merge step_definition_steps
    end

    def get_steps_with_expressions(steps)
      steps_with_expressions = {}
      steps.each do |step_location, step_value|
        if step_value =~ /\#{.*}/
          steps_with_expressions[step_location] = step_value
        end
      end
      steps_with_expressions
    end

    def catalog_possible_dead_steps(steps_with_expressions)
      @step_definitions.each do |step_definition|
        next unless step_definition.calls.empty?
        regex_as_string = step_definition.regex.to_s.gsub(/\(\?-mix:\^?/, "").gsub(/\$\)$/, "")
        steps_with_expressions.each do |step_location, step_value|
          if regex_as_string =~ step_value
            step_definition.add_call(step_location, step_value)
          end
        end
      end
    end

    def convert_steps_with_expressions(steps_with_expressions)
      step_regexs = {}
      steps_with_expressions.each do |step_location, step_value|
        modified_step = step_value.gsub(/\#{[^}]*}/, '.*')
        step_regexs[step_location] = Regexp.new('^' + modified_step + '$')
      end
      step_regexs
    end

    def load_summary_data(summary_hash)
      summary_node = SummaryNode.new
      summary_node.count = summary_hash[:total]
      summary_node.score = summary_hash[:total_score]
      summary_node.average = summary_hash[:average]
      summary_node.threshold = summary_hash[:threshold]
      summary_node.good = summary_hash[:good]
      summary_node.bad = summary_hash[:bad]
      summary_node
    end

    def build_file_list_from_folder(folder_name, extension)
      list = []
      Dir.entries(folder_name).each_entry do |file_name|
        unless FILE_IGNORE_LIST.include?(file_name)
          file_name = "#{folder_name}/#{file_name}"
          if File.directory?(file_name)
            list << build_file_list_from_folder(file_name, extension)
          elsif file_name.downcase.include?(extension)
            list << file_name
          end
        end
      end
      list.flatten
    end

    def build_step_definitions(file_name)
      step_file_lines = []
      step_file = File.open(file_name)
      step_file.each_line { |line| step_file_lines << line }
      step_file.close

      counter = 0
      step_code = []
      step_definitions = []
      found_first_step = false
      until counter >= step_file_lines.length
        if step_file_lines[counter] =~ STEP_DEFINITION_REGEX and !step_code.empty? and found_first_step
          step_definitions << CukeSniffer::StepDefinition.new("#{file_name}:#{counter+1 - step_code.count}", step_code)
          step_code = []
        end
        found_first_step = true if step_file_lines[counter] =~ STEP_DEFINITION_REGEX
        step_code << step_file_lines[counter].strip
        counter+=1
      end
      step_definitions << CukeSniffer::StepDefinition.new("#{file_name}:#{counter+1 -step_code.count}", step_code) unless step_code.empty? or !found_first_step
      step_definitions
    end

    def assess_array(array, type)
      min, max, min_file, max_file = nil
      total = 0
      good = 0
      bad = 0
      total_score = 0
      unless array.empty?
        array.each do |node|
          score = node.score
          @summary[:total_score] += score
          total_score += score
          node.rules_hash.each_key do |key|
            @summary[:improvement_list][key] ||= 0
            @summary[:improvement_list][key] += node.rules_hash[key]
          end
          min, min_file = score, node.location if (min.nil? or score < min)
          max, max_file = score, node.location if (max.nil? or score > max)
          if node.good?
            good += 1
          else
            bad += 1
          end
          total += score
        end
      end
      {
          :total => array.count,
          :total_score => total_score,
          :min => min,
          :min_file => min_file,
          :max => max,
          :max_file => max_file,
          :average => (total.to_f/array.count.to_f).round(2),
          :threshold => THRESHOLDS[type],
          :good => good,
          :bad => bad,
      }
    end

    def get_all_scenarios(features)
      scenarios = []
      features.each do |feature|
        scenarios << feature.background unless feature.background.nil?
        scenarios << feature.scenarios
      end
      scenarios.flatten
    end

    def sort_improvement_list
      sorted_array = @summary[:improvement_list].sort_by { |improvement, occurrence| occurrence }
      @summary[:improvement_list] = {}
      sorted_array.reverse.each { |node|
        @summary[:improvement_list][node[0]] = node[1]
      }
    end

    def create_improvement_list
      output = []
      @summary[:improvement_list].each_key { |improvement| output << "(#{summary[:improvement_list][improvement]})#{improvement}" }
      output
    end

    def extract_steps_from_features
      steps = {}
      @features.each do |feature|
        steps.merge! extract_scenario_steps(feature.background) unless feature.background.nil?
        feature.scenarios.each do |scenario|
          if scenario.type == "Scenario Outline"
            steps.merge! extract_scenario_outline_steps(scenario)
          else
            steps.merge! extract_scenario_steps(scenario)
          end
        end
      end
      steps
    end

    def extract_scenario_steps(scenario)
      steps_hash = {}
      counter = 1
      scenario.steps.each do |step|
        location = scenario.location.gsub(/:\d*$/, ":#{scenario.start_line + counter}")
        steps_hash[location] = step
        counter += 1
      end
      steps_hash
    end

    def extract_scenario_outline_steps(scenario)
      steps = {}
      examples = scenario.examples_table
      return {} if examples.empty?
      variable_list = extract_variables_from_example(examples.first)
      (1...examples.size).each do |example_counter|
        #TODO Abstraction needed for this regex matcher (constants?)
        next if examples[example_counter] =~ /^\#.*$/
        row_variables = extract_variables_from_example(examples[example_counter])
        step_counter = 1
        scenario.steps.each do |step|
          step_line = scenario.start_line + step_counter
          location = "#{scenario.location.gsub(/\d+$/, step_line.to_s)}(Example #{example_counter})"
          steps[location] = build_updated_step_from_example(step, variable_list, row_variables)
          step_counter += 1
        end
      end
      steps
    end

    def build_updated_step_from_example(step, variable_list, row_variables)
      new_step = step.dup
      variable_list.each do |variable|
        if step.include? variable
          table_variable_to_insert = row_variables[variable_list.index(variable)]
          table_variable_to_insert ||= ""
          new_step.gsub!("<#{variable}>", table_variable_to_insert)
        end
      end
      new_step
    end

    def extract_steps_from_step_definitions
      steps = {}
      @step_definitions.each do |definition|
        definition.nested_steps.each_key do |key|
          steps[key] = definition.nested_steps[key]
        end
      end
      steps
    end

    def extract_markup(markup_source)
      markup_location = "#{markup_source}/markup.html.erb"
      markup = ""
      File.open(markup_location).lines.each do |line|
        markup << line
      end
      markup
    end

    def build_hooks(file_name)
      hooks_file_lines = []
      hooks_file = File.open(file_name)
      hooks_file.each_line { |line| hooks_file_lines << line }
      hooks_file.close

      counter = 0
      hooks_code = []
      hooks = []
      found_first_hook = false
      until counter >= hooks_file_lines.length
        if hooks_file_lines[counter] =~ HOOK_REGEX and !hooks_code.empty? and found_first_hook
          hooks << CukeSniffer::Hook.new("#{file_name}:#{counter+1 - hooks_code.count}", hooks_code)
          hooks_code = []
        end
        found_first_hook = true if hooks_file_lines[counter] =~ HOOK_REGEX
        hooks_code << hooks_file_lines[counter].strip
        counter+=1
      end
      hooks << CukeSniffer::Hook.new("#{file_name}:#{counter+1 -hooks_code.count}", hooks_code) unless hooks_code.empty? or !found_first_hook
      hooks
    end
  end

end
