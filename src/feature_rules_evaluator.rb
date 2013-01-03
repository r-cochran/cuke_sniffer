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
    rule_empty_name(self.class.to_s)
    rule_numbers_in_name(self.class.to_s)
    rule_long_name(self.class.to_s)
  end

  def rule_too_many_tags(type)
    store_rule(3, "#{type} has too many tags") if tags.size >= 8
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

  def == (comparison_object)
    super(comparison_object)
    comparison_object.name == name
    comparison_object.tags == tags
  end

end