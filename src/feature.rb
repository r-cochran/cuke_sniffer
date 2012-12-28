class Feature < RulesEvaluator

  attr_accessor :tags, :name, :scenarios

  def initialize(file_name)
    @tags = []
    @name = ""
    @scenarios = []
    split_feature(file_name)
    super(file_name)
  end

  def split_feature(file_name)
    feature_lines = []

    feature_file = File.open(file_name)
    feature_file.each_line { |line| feature_lines << line }
    feature_file.close

    index = 0
    until feature_lines[index].match FEATURE_NAME_REGEX
      create_tag_list(feature_lines[index])
      index += 1
    end

    until index >= feature_lines.length or feature_lines[index].match TAG_REGEX or feature_lines[index].match SCENARIO_TITLE_REGEX
      create_feature_name(feature_lines[index])
      index += 1
    end

    scenario_title_found = false
    index_of_title = nil
    code_block = []
    until index >= feature_lines.length
      if scenario_title_found and (feature_lines[index].match TAG_REGEX or feature_lines[index].match SCENARIO_TITLE_REGEX)
        add_scenario_to_feature(code_block, index_of_title)
        scenario_title_found = false
        code_block = []
      end
      code_block << feature_lines[index].strip
      if feature_lines[index].match SCENARIO_TITLE_REGEX
        scenario_title_found = true
        index_of_title = "#{file_name}:#{index + 1}"
      end
      index += 1
    end
    #TODO - Last scenario falling through above logic, needs a fix (code_block related)
    add_scenario_to_feature(code_block, index_of_title) unless code_block==[]
  end

  def add_scenario_to_feature(code_block, index_of_title)
    scenario = Scenario.new(index_of_title, code_block)
    scenario.tags += @tags
    @scenarios << scenario
  end

  def create_feature_name(line)
    unless is_comment?(line)
      line.gsub!("Feature:", "")
      line.strip!
      @name += " " unless @name.empty? or line.empty?
      @name += line
    end
  end

  def ==(comparison_object)
    comparison_object.location == @location
    comparison_object.tags == @tags
    comparison_object.name == @name
    comparison_object.scenarios == @scenarios
  end

  def evaluate_score
    @score = 1
    @rules_hash = {"Rule Descriptor" => 1}
    scenarios.each do |scenario|
      @score += scenario.score
      scenario.rules_hash.each_key do |rule_descriptor|
        @rules_hash[rule_descriptor] ||= 0
        @rules_hash[rule_descriptor] += scenario.rules_hash[rule_descriptor]
      end
    end
  end
end