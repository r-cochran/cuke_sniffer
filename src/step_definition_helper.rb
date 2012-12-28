class StepDefinitionHelper

  def self.parse_step_definitions(file_name)
    step_hash = {}
    step_file = File.open(file_name)

    step_flag = false
    group_counter = 0
    step_code = []
    step_location = nil
    line_counter = 1

    step_file.each_line do |line|
      if line =~ STEP_DEFINITION_REGEX
        step_flag = true
        step_location = file_name + ":#{line_counter}"
      end
      step_code << line.strip if step_flag
      group_counter += 1 if(is_comment?(line) == false && (line.include?("{") || line.include?("do")))
      group_counter -= 1 if(is_comment?(line) == false && (line.include?("}") || line.include?("end")))

      if group_counter == 0
        if step_code != [] && step_flag
          step_hash[step_location] = step_code
          step_code = []
        end
        step_flag = false
        group_counter = 0
        step_location = nil
      end
      line_counter += 1
    end
    step_file.close
    step_hash
  end

  def self.is_comment?(line)
    if line =~ /^\#.*$/
      true
    else
      false
    end
  end

  def self.build_step_definitions(file_name)
    definitions_of_file = parse_step_definitions(file_name)
    step_definitions = []
    definitions_of_file.each_key do |key|
      step_definitions << StepDefinition.new(key, definitions_of_file[key])
    end
    step_definitions
  end

  def self.build_step_definitions_from_folder(folder_name)
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
    list_of_steps.flatten.uniq
  end
end