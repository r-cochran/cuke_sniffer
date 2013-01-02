class CukeSniffer
  attr_accessor :features, :step_definitions, :summary

  def initialize(features_location = Dir.getwd, step_definitions_location = Dir.getwd)
    @features_location = features_location
    @step_definitions_location = step_definitions_location
    @features = build_features_from_folder(features_location)
    @step_definitions = build_step_definitions_from_folder(step_definitions_location)
    @summary = {
        :total_score => 0,
        :features => {},
        :step_definitions => {},
        :improvement_list => {}
    }
    assess_score
    output_results
  end

  def build_features_from_folder(folder_path)
    features = []
    Dir.entries(folder_path).each_entry do |file_name|
      unless FILE_IGNORE_LIST.include?(file_name)
        file_name = "#{folder_path}/#{file_name}"
        if File.directory?(file_name)
          features << build_features_from_folder(file_name)
        elsif file_name.include?(".feature")
          features << Feature.new(file_name)
        end
      end
    end
    features.flatten
  end

  def build_step_definitions(file_name)
    step_file_lines = []
    step_file = File.open(file_name)
    step_file.each_line { |line| step_file_lines << line }
    step_file.close

    counter = 0
    step_code = []
    step_definitions = []
    until counter >= step_file_lines.length
      if step_file_lines[counter] =~ STEP_DEFINITION_REGEX && !step_code.empty?
        step_definitions << StepDefinition.new("#{file_name}:#{counter+1 - step_code.count}", step_code)
        step_code = []
      end
      step_code << step_file_lines[counter].strip
      counter+=1
    end
    step_definitions << StepDefinition.new("#{file_name}:#{counter+1}", step_code)
    step_definitions
  end

  def build_step_definitions_from_folder(folder_name)
    list_of_steps = []
    Dir.entries(folder_name).each_entry do |file_name|
      unless FILE_IGNORE_LIST.include?(file_name)
        file_name = "#{folder_name}/#{file_name}"
        if File.directory?(file_name)
          list_of_steps << build_step_definitions_from_folder(file_name)
        elsif file_name.include?("steps.rb")
          list_of_steps << build_step_definitions(file_name)
        end
      end
    end
    list_of_steps.flatten
  end

  def assess_array(array)
    min = nil
    max = nil
    total = 0
    array.each do |node|
      score = node.score
      @summary[:total_score] += score
      node.rules_hash.each_key do |key|
        @summary[:improvement_list][key] ||= 0
        @summary[:improvement_list][key] += node.rules_hash[key]
      end
      min = score if (min.nil? or score < min)
      max = score if (max.nil? or score > max)
      total += score
    end
    {
        :min => min,
        :max => max,
        :average => total/array.count
    }
  end

  def assess_score
    @summary[:features] = assess_array(@features)
    @summary[:step_definitions] = assess_array(@step_definitions) unless @step_definitions.empty?
  end

  def output_results
    feature_results = @summary[:features]
    step_definition_results = @summary[:step_definitions]
    #todo this string is completely dependent on the tabbing in the string
    output = "Suite Summary
  Total Score: #{@summary[:total_score]}
    Features (#@features_location)
      Min: #{feature_results[:min]}
      Max: #{feature_results[:max]}
      Average: #{feature_results[:average]}
    Step Definitions (#@step_definitions_location)
      Min: #{step_definition_results[:min]}
      Max: #{step_definition_results[:max]}
      Average: #{step_definition_results[:average]}
  Improvements to make:"
    @summary[:improvement_list].each_key { |improvement| output << "\n    (#{summary[:improvement_list][improvement]})#{improvement}" }
    output
  end

  def catalog_step_calls
    @features.each do |feature|
      feature.scenarios.each do |scenario|
        scenario_line = scenario.start_line
        scenario.steps.each do |step|
          scenario_line += 1
          update_step_definition(scenario.location.gsub(scenario.start_line.to_s, scenario_line.to_s), step)
        end
      end
    end

    @step_definitions.each do |definition|
      next if definition.calls.empty?
      definition.nested_steps.each_key do |key|
        update_step_definition(key, definition.nested_steps[key])
      end
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
    catalog_step_calls
    dead_steps = []
    @step_definitions.each do |step_definition|
      dead_steps << step_definition if step_definition.calls.empty?
    end
    dead_steps
  end

end

