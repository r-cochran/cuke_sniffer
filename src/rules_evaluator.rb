class RulesEvaluator
  attr_accessor :location, :score, :rules_hash

  def initialize(location)
    @location = location
    @score = 0
    @rules_hash = {}
  end

  def evaluate_score
  end

  def store_rule(score, description)
    @score += score
    @rules_hash[description] ||= 0
    @rules_hash[description] += 1
  end

  def is_comment?(line)
    if line =~ /^\#.*$/
      true
    else
      false
    end
  end

  def == (comparison_object)
    comparison_object.location == location
    comparison_object.score == score
    comparison_object.rules_hash == rules_hash
  end
end