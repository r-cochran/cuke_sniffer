class Scenario < FeatureRulesEvaluator
  attr_accessor :start_line, :type, :steps, :examples_table

  def initialize(location, scenario)
    super(location)
    @start_line = location.match(/:(?<line>\d*)/)[:line].to_i
    @steps = []
    @examples_table = []
    split_scenario(scenario)
    evaluate_score
  end

  def split_scenario(scenario)
    index = 0
    until scenario[index] =~ SCENARIO_TITLE_STYLES
      create_tag_list(scenario[index])
      index += 1
    end

    @type = scenario[index].match(SCENARIO_TITLE_STYLES)[:type]

    until index >= scenario.length or scenario[index].match STEP_REGEX or scenario[index].include?("Examples:")
      create_name(scenario[index], SCENARIO_TITLE_STYLES)
      index += 1
    end

    until index >= scenario.length or scenario[index].include?("Examples:")
      @steps << scenario[index] if scenario[index].match STEP_REGEX
      index += 1
    end

    if index < scenario.length and scenario[index].include?("Examples:")
      index += 1
      until index >= scenario.length
        @examples_table << scenario[index] unless scenario[index].empty?
        index += 1
      end
    end
  end

  def ==(comparison_object)
    super(comparison_object)
    comparison_object.steps == steps
    comparison_object.examples_table == examples_table
  end

  def evaluate_score
    super
    evaluate_scenario_scores
  end

  def get_step_order
    order = []
    @steps.each { |line|
      match = line.match(STEP_REGEX)
      order << match[:style] unless match.nil?
    }
    order
  end

  def evaluate_scenario_scores
    rule_empty_scenario
    rule_too_many_steps
    rule_step_order
    rule_invalid_first_step
    rule_asterisk_step
    rule_commented_step
    rule_implementation_details_used
    rule_date_used_in_step

    if type == "Scenario Outline"
      rule_no_examples_table
      rule_no_examples
      rule_single_example
      rule_too_many_examples
      rule_commented_example
    end
  end

  def rule_empty_scenario
    store_rule(3, "Scenario with no steps!") if @steps.empty?
  end

  def rule_too_many_steps
    store_rule(2, "Scenario has too many steps") if @steps.size >= 7
  end

  def rule_step_order
    step_order = get_step_order.uniq
    %w(But * And).each { |type| step_order.delete(type) }
    store_rule(5, "Steps are out of Given/When/Then order") unless step_order == %w(Given When Then) or step_order == %w(When Then)
  end

  def rule_invalid_first_step
    first_step = get_step_order.first
    store_rule(5, "First step began with And/But") if %w(And But).include?(first_step)
  end

  def rule_asterisk_step
    get_step_order.count('*').times { store_rule(2, "Steps includes a *") }
  end

  def rule_commented_step
    @steps.each do |step|
      store_rule(3, "Commented Step") if is_comment?(step)
    end
  end

  def rule_implementation_details_used
    implementation_details = %w(site page)
    @steps.each do |step|
      implementation_details.each do |phrase|
        store_rule(2, "Implementation word used: #{phrase}") if step.include?(phrase)
      end
    end
  end

  def rule_date_used_in_step
    @steps.each do |step|
      store_rule(1, "Date used: #{step.match(DATE_REGEX)[:date]}") if step =~ DATE_REGEX
    end
  end

  def rule_no_examples_table
    store_rule(10, "Scenario Outline with no examples table") if @examples_table.empty?
  end

  def rule_no_examples
    store_rule(5, "Scenario Outline with only no examples") if @examples_table.size == 1
  end

  def rule_single_example
    store_rule(3, "Scenario Outline with only one example") if @examples_table.size == 2 and !is_comment?(@examples_table[1])
  end

  def rule_too_many_examples
    store_rule(5, "Scenario Outline with too many examples") if (@examples_table.size - 1) >= 8
  end

  def rule_commented_example
    @examples_table.each do |example|
      store_rule(3, "Commented Example") if is_comment?(example)
    end
  end

end