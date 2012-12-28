class DeadStepsSorter
  FILE_IGNORE_LIST = [".", ".."]
  FEATURE_STEP_REGEX = /(Given|And|When|Then|Or|[*])\s(?<step>.+)$/x
  STEPS_STEP_REGEX = /\/\^(?<step>.+)\$\//x

  def get_list_of_steps_from_feature_file(file_name)
    list_of_steps = []
    File.open(file_name).each_line do |line|
      if line =~ FEATURE_STEP_REGEX
        list_of_steps << FEATURE_STEP_REGEX.match(line)[:step]
      end
    end
    list_of_steps
  end

  def get_list_of_steps_from_features_folder(folder_name)
    list_of_steps = []
    Dir.entries(folder_name).each_entry do |file_name|
      unless FILE_IGNORE_LIST.include?(file_name)
        if file_name.include?(".feature")
          list_of_steps << get_list_of_steps_from_feature_file(folder_name + "/" + file_name)
        else
          list_of_steps << get_list_of_steps_from_features_folder(folder_name + "/" + file_name)
        end
      end
    end
    list_of_steps.flatten.uniq
  end

  def get_list_of_steps_from_step_file(file_name)
    list_of_steps = []
    step_file = File.open(file_name)
    step_file.each_line do |line|
      if line =~ STEPS_STEP_REGEX
        list_of_steps << STEPS_STEP_REGEX.match(line)[:step]
      end
    end
    step_file.close
    list_of_steps
  end

  def get_list_of_steps_from_step_definition_folder(folder_name)
    list_of_steps = []
    Dir.entries(folder_name).each_entry do |file_name|
      unless FILE_IGNORE_LIST.include?(file_name)
        if file_name.include?("steps.rb")
          list_of_steps << get_list_of_steps_from_step_file(folder_name + "/" + file_name)
        else
          list_of_steps << get_list_of_steps_from_step_definition_folder(folder_name + "/" + file_name)
        end
      end
    end
    list_of_steps.flatten.uniq
  end

  def regex_in_step_list?(regex, step_list)
    step_list.each do |step|
      return true if (step =~ regex)
    end
    false
  end

  def get_list_of_dead_steps(feature_list_of_steps, step_list_of_steps)
    list_of_dead_steps = []
    step_list_of_steps.each do |step|
      step_regex = Regexp.new(step)

      unless regex_in_step_list?(step_regex, feature_list_of_steps)
        list_of_dead_steps << step
      end
    end
    list_of_dead_steps
  end

  def get_step_code(step, file_name)
    step_code = ""
    step_regex = Regexp.new(step)
    open_tag_count = 0
    record_flag = false
    file = File.open(file_name)
    file.each_line do |line|
      record_flag = true if (line =~ step_regex)
      step_code << line if (record_flag)
      open_tag_count += 1 if (line.include?("{") or line.include?("do"))
      open_tag_count -= 1 if (line.include?("}") or line.include?("end"))
      record_flag = false if (open_tag_count == 0)
    end
    file.close
    step_code
  end

  def move_dead_steps(step_definitions_folder, list_of_dead_steps, dead_steps_file_name = "dead_steps.rb")
    Dir.entries(step_definitions_folder).each_entry do |file_name|
      unless FILE_IGNORE_LIST.include?(file_name)
        file_name = "#{step_definitions_folder}#{file_name}"
        if file_name.include?("steps.rb")
          dead_steps_file = File.open(dead_steps_file_name, "a")
          steps_of_file = get_list_of_steps_from_step_file(file_name)
          steps_of_file.each do |step|
            if list_of_dead_steps.include?(step)
              dead_steps_file.puts("##{file_name}")
              dead_steps_file.puts get_step_code(step, file_name)
            end
          end
          dead_steps_file.close
        elsif File.directory?(file_name)
          move_dead_steps(file_name + "/", list_of_dead_steps, dead_steps_file_name)
        end
      end
    end
  end
end