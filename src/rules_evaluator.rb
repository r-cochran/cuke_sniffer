class RulesEvaluator
  attr_accessor :location, :score, :rules_hash

  def initialize(location)
    @location = location
    @score = 0
    @rules_hash = {}
    evaluate_score
  end

  def evaluate_score
  end

  def store_rule(score, description)
    @score += score
    @rules_hash[description] ||= 0
    @rules_hash[description] += 1
  end

  def rule_empty_name(type)
    store_rule(3, "No #{type} Description!") if name.empty?
  end

  def rule_numbers_in_name(type)
    store_rule(3, "#{type} has number(s) in the title") if name =~ /\d/
  end

  def rule_long_name(type)
    store_rule(0.5, "#{type} title is too long") if name.size >= 180
  end

  def rule_too_many_tags(type)
    store_rule(3, "#{type} has too many tags") if tags.size >= 8
  end

  def create_tag_list(line)
    if TAG_REGEX.match(line) and !is_comment?(line)
      line.scan(TAG_REGEX).each { |tag| tags << tag[0] }
    end
  end

  def is_comment?(line)
    if line =~ /^\#.*$/
      true
    else
      false
    end
  end
end