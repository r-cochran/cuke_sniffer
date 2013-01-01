class Scenario < RulesEvaluator
  attr_accessor :start_line, :name, :tags, :steps, :examples_table

  def initialize(location, scenario)
    @start_line = location.match(/:(?<line>\d*)/)[:line].to_i
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
    comparison_object.location == location
    comparison_object.name == name
    comparison_object.steps == steps
    comparison_object.examples_table == examples_table
    comparison_object.tags == tags
  end

  def evaluate_score
    super
    evaluate_scenario_scores
  end

  def evaluate_scenario_scores
    rule_empty_name("Scenario")
    rule_numbers_in_name("Scenario")
    rule_long_name("Scenario")

    rule_empty_scenario
    rule_too_many_steps
    rule_step_order
    rule_invalid_first_step
    rule_asterisk_step
  end

  def rule_asterisk_step
    get_step_order.count('*').times {store_rule(2, "Steps includes a *")}
  end

  def rule_invalid_first_step
    first_step = get_step_order.first
    store_rule(5, "First step began with And/But") if %w(And But).include?(first_step)
  end

  def get_step_order
    order = []
    @steps.each{|line|
      match = line.match(STEP_REGEX)
      order << match[:style] unless match.nil?
    }
    order
  end

  def rule_step_order
    step_order = get_step_order.uniq
    %w(But * And).each{|type| step_order.delete(type)}
    store_rule(5, "Steps are out of Given/When/Then order") unless step_order == %w(Given When Then) or step_order == %w(When Then)
  end

  def rule_too_many_steps
    store_rule(2, "Scenario has too many steps") if @steps.size >= 7
  end

  def rule_empty_scenario
    store_rule(3, "Scenario with no steps!") if @steps.empty?
  end
end