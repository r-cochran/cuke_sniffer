class RulesEvaluator
  attr_accessor :location, :score, :rules_hash

  def initialize(location)
    @location = location
    @score = 0
    @rules_hash = {}
    evaluate_score
  end

  def evaluate_score
    @score = 1
    @rules_hash = {"Rule Descriptor" => 1}
  end

  def create_tag_list(line)
    if TAG_REGEX.match(line) and !is_comment?(line)
      line.scan(TAG_REGEX).each { |tag| @tags << tag[0] }
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