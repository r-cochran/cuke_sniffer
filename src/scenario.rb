class Scenario < RulesEvaluator
  attr_accessor :name, :tags, :steps, :examples_table

  def initialize(location, scenario)
    @name = ""
    @tags = []
    @steps = []
    @examples_table = []
    split_scenario(scenario)
    super(location)
  end

  def split_scenario(scenario)
    index = 0
    until scenario[index].match SCENARIO_TITLE_REGEX
      create_tag_list(scenario[index])
      index += 1
    end

    until index >= scenario.length or scenario[index].match STEP_REGEX
      create_scenario_name(scenario[index])
      index += 1
    end

    until index >= scenario.length or scenario[index].include?("Examples:")
      @steps << scenario[index]
      index += 1
    end

    if index < scenario.length and scenario[index].include?("Examples")
      index += 1
      until index >= scenario.length
        @examples_table << scenario[index]
        index += 1
      end
    end
  end

  def create_scenario_name(line)
    unless is_comment?(line)
      line.gsub!(SCENARIO_TITLE_STYLES, "")
      line.strip!
      @name += " " unless @name.empty? or line.empty?
      @name += line
    end
  end

  def ==(comparison_object)
    comparison_object.location == @location
    comparison_object.name == @name
    comparison_object.steps == @steps
    comparison_object.examples_table == @examples_table
    comparison_object.tags == @tags
  end

  def evaluate_score
    super
    evaluate_scenario_scores
  end

  def evaluate_scenario_scores
    rule_empty_name("Scenario")
    rule_empty_scenario
  end

  def rule_empty_scenario
    if @steps.empty?
      @score += 3
      @rules_hash["Scenario with no steps!"] = 1
    end
  end
end