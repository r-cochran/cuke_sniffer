class CukeSniffer
  attr_accessor :features, :step_definitions, :summary

  def initialize(features_location = Dir.getwd, step_definitions_location = Dir.getwd + "/step_definitions")
    @features_location = features_location
    @step_definitions_location = step_definitions_location
    @features = FeatureHelper.build_features_from_folder(features_location)
    @step_definitions = StepDefinitionHelper.build_step_definitions_from_folder(step_definitions_location)
    @summary = {
        :total_score => 0,
        :features => {},
        :step_definitions => {},
        :improvement_list => []
    }
    assess_score
    output_results
  end

  def assess_array(array)
    min = nil
    max = nil
    total = 0
    array.each do |node|
      score = node.score
      @summary[:total_score] += score
      @summary[:improvement_list] << node.rules_hash.keys
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
    @summary[:features] = assess_array(@features.values)
    @summary[:step_definitions] = assess_array(@step_definitions)
    @summary[:improvement_list].flatten!.uniq!
  end

  def extract_steps_from_feature
    steps_hash = {}
    @features.each_key do |key|
      sub_feature = @features[key]
      sub_feature.scenarios.each do |scenario|
        path = /(?<path>.*):(?<line_number>\d*)/.match(scenario.location)[:path]
        line_number = /(?<path>.*):(?<line_number>\d*)/.match(scenario.location)[:line_number].to_i
        counter = 1
        scenario.steps.each do |step|
          steps_hash["#{path}:#{line_number + counter}"] = step
          counter += 1
        end
      end
    end
    steps_hash
  end

  def extract_steps_from_step_definitions
    steps_hash = {}
    @step_definitions.each do |step_definition|
      step_definition.nested_steps.each do |nested_step|
        path = /(?<path>.*):(?<line_number>\d*)/.match(step_definition.location)[:path]
        line_number = /(?<path>.*):(?<line_number>\d*)/.match(step_definition.location)[:line_number].to_i
        counter = 1
        step_definition.code.each do |code|
          break if (code.include?(nested_step))
          counter += 1
        end
        steps_hash["#{path}:#{line_number + counter}"] = nested_step
      end
    end
    steps_hash
  end

  def output_results
    feature_results = @summary[:features]
    step_definition_results = @summary[:step_definitions]
    #todo this string is completely dependent on the tabbing in the string
    output = "Suite Summary
  Total Score: #{@summary[:total_score]}
    Features (#{@features_location})
      Min: #{feature_results[:min]}
      Max: #{feature_results[:max]}
      Average: #{feature_results[:average]}
    Step Definitions (#{@step_definitions_location})
      Min: #{step_definition_results[:min]}
      Max: #{step_definition_results[:max]}
      Average: #{step_definition_results[:average]}
  Improvements to make:"
    @summary[:improvement_list].each { |improvement| output << "\n    #{improvement}" }
    output
  end
end