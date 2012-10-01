class CukeSniffer
  attr_accessor :features, :step_definitions

  def initialize(features_location, step_definitions_location)
    @features = FeatureHelper.build_features_from_folder(features_location)
    @step_definitions = StepDefinitionHelper.build_step_definitions_from_folder(step_definitions_location)
  end

  def extract_steps_from_feature
    steps_hash = {}
    @features.each_key { |key|
      sub_feature = @features[key]
      sub_feature.scenarios.each{|scenario|
        path = /(?<path>.*):(?<line_number>\d*)/.match(scenario.location)[:path]
        line_number = /(?<path>.*):(?<line_number>\d*)/.match(scenario.location)[:line_number].to_i
        counter = 1
        scenario.steps.each{|step|
          steps_hash["#{path}:#{line_number + counter}"] = step
          counter += 1
        }
      }
    }
    steps_hash
  end

  def extract_steps_from_step_definitions
    steps_hash = {}
    @step_definitions.each{|step_definition|
      step_definition.nested_steps.each{|nested_step|
        path = /(?<path>.*):(?<line_number>\d*)/.match(step_definition.location)[:path]
        line_number = /(?<path>.*):(?<line_number>\d*)/.match(step_definition.location)[:line_number].to_i
        counter = 1
        step_definition.code.each{|code|
          break if(code.include?(nested_step))
          counter += 1
        }
        steps_hash["#{path}:#{line_number + counter}"] = nested_step
      }
    }
    steps_hash
  end
end