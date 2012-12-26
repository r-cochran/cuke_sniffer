class Feature
  FEATURE_NAME_REGEX = /Feature:\s*(?<name>.*)/
  TAG_REGEX = /(?<tag>@\S*)/
  SCENARIO_TITLE_REGEX = /(Scenario:|Scenario Outline:|Scenario Template:)\s(?<name>.*)/

  attr_accessor :location, :tags, :name, :scenarios

  def initialize(file_name)
    @location = file_name
    @tags = []
    @name = ""
    @scenarios = []
    split_feature(file_name)
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
      code_block << feature_lines[index]
      if (feature_lines[index].match SCENARIO_TITLE_REGEX)
        scenario_title_found = true
        index_of_title = "#{file_name}:#{index + 1}"
      end
      index += 1
    end
    #TODO - FIX ME YOU SONOFABITCH
    add_scenario_to_feature(code_block, index_of_title) unless code_block==[]
  end

  def add_scenario_to_feature(code_block, index_of_title)
    scenario = Scenario.new(index_of_title, code_block)
    scenario.tags += @tags
    @scenarios << scenario
  end

  def create_tag_list(line)
    unless (TAG_REGEX.match(line).nil?)
      unless is_comment?(line)
        line.scan(TAG_REGEX).each { |tag| @tags << tag[0] }
      end
    end
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


  #todo make a helper method somewhere
  def is_comment?(line)
    if line =~ /^\#.*$/
      true
    else
      false
    end
  end
end