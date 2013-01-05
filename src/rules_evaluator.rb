class RulesEvaluator
  attr_accessor :location, :score, :rules_hash

  def initialize(location)
    @location = location
    @score = 0
    @rules_hash = {}
  end

  def evaluate_score
  end

  def store_rule(rule)
    if rule[:enabled]
      @score += rule[:score]
      @rules_hash[rule[:phrase]] ||= 0
      @rules_hash[rule[:phrase]] += 1
    end
  end

  def store_updated_rule(rule, phrase)
    store_rule({:enabled => rule[:enabled], :score => rule[:score], :phrase => phrase})
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