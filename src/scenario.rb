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
    until index >= scenario.length or scenario[index] =~ SCENARIO_TITLE_STYLES
      update_tag_list(scenario[index])
      index += 1
    end

    until index >= scenario.length or scenario[index].match STEP_REGEX or scenario[index].include?("Examples:")
      match = scenario[index].match(SCENARIO_TITLE_STYLES)
      @type = match[:type] unless match.nil?
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

  def get_step_order
    order = []
    @steps.each { |line|
      match = line.match(STEP_REGEX)
      order << match[:style] unless match.nil?
    }
    order
  end

  def evaluate_score
    super
    rule_empty_scenario
    rule_too_many_steps
    rule_step_order
    rule_invalid_first_step
    rule_asterisk_step
    rule_commented_step
    rule_implementation_words
    rule_date_used_in_step
    evaluate_outline_scores if type == "Scenario Outline"
  end

  def evaluate_outline_scores
      rule_no_examples_table
      rule_no_examples
      rule_one_example
      rule_too_many_examples
      rule_commented_example
  end

  def rule_empty_scenario
    store_rule(SCENARIO_RULES[:no_steps]) if @steps.empty?
  end

  def rule_too_many_steps
    rule = SCENARIO_RULES[:too_many_steps]
    store_rule(rule) if @steps.size >= rule[:max]
  end

  def rule_step_order
    step_order = get_step_order.uniq
    %w(But * And).each { |type| step_order.delete(type) }
    store_rule(SCENARIO_RULES[:out_of_order_steps]) unless step_order == %w(Given When Then) or step_order == %w(When Then)
  end

  def rule_invalid_first_step
    first_step = get_step_order.first
    store_rule(SCENARIO_RULES[:invalid_first_step]) if %w(And But).include?(first_step)
  end

  def rule_asterisk_step
    get_step_order.count('*').times { store_rule(SCENARIO_RULES[:asterisk_step]) }
  end

  def rule_commented_step
    @steps.each do |step|
      store_rule(SCENARIO_RULES[:commented_step]) if is_comment?(step)
    end
  end

  def rule_implementation_words
    rule = SHARED_RULES[:implementation_word]
    @steps.each do |step|
      rule[:words].each do |word|
        store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, word)) if step.include?(word)
      end
    end
  end

  def rule_date_used_in_step
    @steps.each do |step|
      store_rule(SCENARIO_RULES[:date_used]) if step =~ DATE_REGEX
    end
  end

  def rule_no_examples_table
    store_rule(SCENARIO_RULES[:no_examples_table]) if @examples_table.empty?
  end

  def rule_no_examples
    store_rule(SCENARIO_RULES[:no_examples]) if @examples_table.size == 1
  end

  def rule_one_example
    store_rule(SCENARIO_RULES[:one_example]) if @examples_table.size == 2 and !is_comment?(@examples_table[1])
  end

  def rule_too_many_examples
    store_rule(SCENARIO_RULES[:too_many_examples]) if (@examples_table.size - 1) >= 8
  end

  def rule_commented_example
    @examples_table.each do |example|
      store_rule(SCENARIO_RULES[:commented_example]) if is_comment?(example)
    end
  end

end