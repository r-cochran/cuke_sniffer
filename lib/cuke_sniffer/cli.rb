require 'erb'

module CukeSniffer
  class CLI
    include CukeSniffer::Constants

    attr_accessor :features, :step_definitions, :summary

    def initialize(features_location = Dir.getwd, step_definitions_location = Dir.getwd)
      @features_location = features_location
      @step_definitions_location = step_definitions_location
      @features = []
      @step_definitions = []

      puts "\nFeatures:"
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
      @summary = {
        :total_score => 0,
        :features => {},
        :step_definitions => {},
        :improvement_list => {}
      }
      puts "\nCataloging Step Calls: "
      catalog_step_calls
      puts "\nAssessing Score: "
      assess_score
    end

    def good?
      @summary[:total_score] <= Constants::THRESHOLDS["Project"]
    end

    def problem_percentage
      @summary[:total_score].to_f / Constants::THRESHOLDS["Project"].to_f
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
      step_definitions << CukeSniffer::StepDefinition.new("#{file_name}:#{counter+1}", step_code) unless step_code.empty? or !found_first_step
      step_definitions
    end

    def assess_array(array)
      min, max, min_file, max_file = nil
      total = 0
      array.each do |node|
        score = node.score
        @summary[:total_score] += score
        node.rules_hash.each_key do |key|
          @summary[:improvement_list][key] ||= 0
          @summary[:improvement_list][key] += node.rules_hash[key]
        end
        min, min_file = score, node.location if (min.nil? or score < min)
        max, max_file = score, node.location if (max.nil? or score > max)
        total += score
      end
      {
        :total => array.count,
        :min => min,
        :min_file => min_file,
        :max => max,
        :max_file => max_file,
        :average => (total.to_f/array.count.to_f).round(2)
      }
    end

    def assess_score
      @summary[:features] = assess_array(@features)
      @summary[:step_definitions] = assess_array(@step_definitions) unless @step_definitions.empty?
      sort_improvement_list
    end

    def sort_improvement_list
      sorted_array = @summary[:improvement_list].sort_by { |improvement, occurrence| occurrence }
      @summary[:improvement_list] = {}
      sorted_array.reverse.each { |node|
        @summary[:improvement_list][node[0]] = node[1]
      }
    end

    def output_results
      feature_results = @summary[:features]
      step_definition_results = @summary[:step_definitions]
      output = "Suite Summary
  Total Score: #{@summary[:total_score]}
    Features (#@features_location)
      Min: #{feature_results[:min]} (#{feature_results[:min_file]})
      Max: #{feature_results[:max]} (#{feature_results[:max_file]})
      Average: #{feature_results[:average]}
    Step Definitions (#@step_definitions_location)
      Min: #{step_definition_results[:min]} (#{step_definition_results[:min_file]})
      Max: #{step_definition_results[:max]} (#{step_definition_results[:max_file]})
      Average: #{step_definition_results[:average]}
  Improvements to make:"
      create_improvement_list.each { |item| output << "\n    #{item}" }
      output
    end

    def create_improvement_list
      output = []
      @summary[:improvement_list].each_key { |improvement| output << "(#{summary[:improvement_list][improvement]})#{improvement}" }
      output
    end

    def get_all_steps
      steps = {}
      @features.each do |feature|
        feature.scenarios.each do |scenario|
          counter = 1
          scenario.steps.each do |step|
            location = scenario.location.gsub(/:\d*/, ":#{scenario.start_line + counter}")
            steps[location] = step
            counter += 1
          end
        end
      end
      @step_definitions.each do |definition|
        definition.nested_steps.each_key do |key|
          steps[key] = definition.nested_steps[key]
        end
      end
      steps
    end

    def catalog_step_calls
      steps = get_all_steps
      @step_definitions.each do |step_definition|
        print '.'
        calls = steps.find_all { |location, step| step.gsub(STEP_STYLES, "") =~ step_definition.regex }
        calls.each { |call|
          step_definition.add_call(call[0], call[1])
        }
      end
    end

    def update_step_definition(location, step)
      @step_definitions.each do |step_definition|
        if step.gsub(STEP_STYLES, "") =~ step_definition.regex
          step_definition.add_call(location, step)
          break
        end
      end
    end

    def get_dead_steps
      dead_steps = []
      @step_definitions.each do |step_definition|
        dead_steps << step_definition if step_definition.calls.empty?
      end
      dead_steps
    end

    def sort_by_score(array)
      array.sort_by { |item| item.score }.reverse
    end

    def extract_markup
      markup_location = File.join(File.dirname(__FILE__), 'report', 'markup.rhtml')
      markup = ""
      File.open(markup_location).lines.each do |line|
        markup << line
      end
      markup
    end

    def output_html(file_name = "cuke_sniffer_results.html", cuke_sniffer = self)
      @features = sort_by_score(@features)
      @step_definitions = sort_by_score(@step_definitions)

      markup_erb = ERB.new extract_markup
      output = markup_erb.result(binding)
      File.open(file_name, 'w') do |f|
        f.write(output)
      end
    end
  end
end
