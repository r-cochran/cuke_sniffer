class StepDefinitionHelper

  def self.build_step_definitions(file_name)
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

  def self.is_comment?(line)
    if line =~ /^\#.*$/
      true
    else
      false
    end
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
    list_of_steps.flatten
  end
end