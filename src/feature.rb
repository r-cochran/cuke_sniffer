class Feature
  FEATURE_NAME_REGEX = /Feature: (?<name>.*)/
  TAG_REGEX = /(?<tag>@\S*)/
  SCENARIO_TITLE_REGEX = /(Scenario:|Scenario Outline:|Scenario Template:)\s(?<name>.*)/

  attr_accessor :location, :tags, :name, :scenarios

  def initialize(file_name)
    @location = file_name
    @tags = []
    @name = nil
    @scenarios = []
    split_feature(file_name)
  end

  def split_feature(file_name)
    scenario_location = nil
    line_counter = 0
    code_block = []
    feature_file = File.open(file_name)

    total_lines = 0
    feature_file.each_line{total_lines += 1}
    feature_file.close


    feature_file = File.open(file_name)
    feature_file.each_line { |line|
      line_counter += 1
      unless (TAG_REGEX.match(line).nil?)
        unless is_comment?(line) || @name.nil? == false
          line.scan(TAG_REGEX).each { |tag| @tags << tag[0] }
        end
      end

      unless FEATURE_NAME_REGEX.match(line).nil?
        @name = FEATURE_NAME_REGEX.match(line)[:name]
        next
      end

      if(SCENARIO_TITLE_REGEX.match(line))
        if scenario_location.nil? == false
          not_my_code = []
          code_block.reverse.each{|code|
            if(code == "" || TAG_REGEX.match(code))
              not_my_code << code
            else
              break
            end
          }
          scenario = Scenario.new(scenario_location, code_block - not_my_code)
          scenario.tags += @tags
          @scenarios << scenario
          code_block = not_my_code
        end
        scenario_location = "#{file_name}:#{line_counter}"
      end

      code_block << line.strip unless @name.nil?
    }
    scenario = Scenario.new(scenario_location, code_block)
    scenario.tags += @tags
    @scenarios << scenario

    feature_file.close
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