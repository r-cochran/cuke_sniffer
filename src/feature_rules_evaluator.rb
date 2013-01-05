class FeatureRulesEvaluator < RulesEvaluator
  attr_accessor :tags, :name

  def initialize(location)
    @name = ""
    @tags = []
    super(location)
  end

  def create_name(line, filter)
    line.gsub!(/#{COMMENT_REGEX}#{filter}/, "")
    line.strip!
    @name += " " unless @name.empty? or line.empty?
    @name += line
  end

  def update_tag_list(line)
    if TAG_REGEX.match(line) && !is_comment?(line)
      line.scan(TAG_REGEX).each { |tag| @tags << tag[0] }
    else
      @tags << line.strip unless line.empty?
    end
  end

  def evaluate_score
    super
    rule_too_many_tags(self.class.to_s)
    rule_no_description(self.class.to_s)
    rule_numbers_in_name(self.class.to_s)
    rule_long_name(self.class.to_s)
  end

  def rule_too_many_tags(type)
    rule = SHARED_RULES[:too_many_tags]
    store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type)) if tags.size >= rule[:max]
  end

  def rule_no_description(type)
    rule = SHARED_RULES[:no_description]
    store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type)) if name.empty?
  end

  def rule_numbers_in_name(type)
    rule = SHARED_RULES[:numbers_in_description]
    store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type)) if name =~ /\d/
  end

  def rule_long_name(type)
    rule = SHARED_RULES[:long_name]
    store_updated_rule(rule, rule[:phrase].gsub(/{.*}/, type))  if name.size >= rule[:max]
  end

  def == (comparison_object)
    super(comparison_object)
    comparison_object.name == name
    comparison_object.tags == tags
  end

end