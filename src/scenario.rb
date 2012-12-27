class Scenario
  attr_accessor :location, :name, :tags, :steps, :examples_table, :score, :rules_hash
  SCENARIO_TITLE_REGEX = /(Scenario:|Scenario Outline:|Scenario Template:)\s(?<name>.*)/
  TAG_REGEX = /(?<tag>@\S*)/

  def initialize(location, scenario)
    @location = location
    @tags = []
    @steps = []
    @examples_table = []
    @score = 0
    @rules_hash = {}
    split_scenario(scenario)
    evaluate_score
  end

  def split_scenario(scenario)
    name_found = false
    examples_found = false
    scenario.each{|line|
      unless(TAG_REGEX.match(line).nil?)
        line.scan(TAG_REGEX).each{|tag| @tags << tag[0]}
      end

      unless(SCENARIO_TITLE_REGEX.match(line).nil?)
        @name = SCENARIO_TITLE_REGEX.match(line)[:name]
        name_found = true
        next
      end

      if(line.include?("Examples:"))
        name_found = false
        examples_found = true
        next
      end

      @steps << line if name_found
      @examples_table << line if examples_found
    }
  end

  def ==(comparison_object)
    comparison_object.location == @location
    comparison_object.name == @name
    comparison_object.steps == @steps
    comparison_object.examples_table == @examples_table
    comparison_object.tags == @tags
  end

  def evaluate_score
    @score = 1
    @rules_hash = {"Rule Descriptor" => 1}
  end

end