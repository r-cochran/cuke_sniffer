module CukeSniffer

  # Contains the rules and various scores used in evaluating objects
  module RuleConfig

    # Will prevent suite from executing properly
    FATAL = 100

    # Will cause problem with debugging
    ERROR = 25

    # Readability/misuse of cucumber
    WARNING = 10

    # Small improvements that can be made
    INFO = 1

    fatal_rules = {
        :no_examples => {
            :enabled => true,
            :phrase => "Scenario Outline with no examples.",
            :score => FATAL,
            :targets => ["Scenario"],
            :reason => "object.type == \"Scenario Outline\" and object.examples_table.size == 1"
        },
        :no_examples_table => {
            :enabled => true,
            :phrase => "Scenario Outline with no examples table.",
            :score => FATAL,
            :targets => ["Scenario"],
            :reason => "object.type == \"Scenario Outline\" and object.examples_table.empty?"
        },
        :recursive_nested_step => {
            :enabled => true,
            :phrase => "Recursive nested step call.",
            :score => FATAL,
            :targets => ["StepDefinition"],
            :reason => "object.nested_steps.each_value {|nested_step| store_rule(object, rule) if nested_step =~ object.regex}"
        },
        :background_with_tag => {
            :enabled => true,
            :phrase => "There is a background with a tag. This feature file cannot run!",
            :score => FATAL,
            :targets => ["Background"],
            :reason =>  "object.tags.size > 0"
        },
        :comment_after_tag => {
            :enabled => true,
            :phrase => "Comment comes between tag and properly executing line. This feature file cannot run!",
            :score => FATAL,
            :targets => ["Feature", "Scenario"],
            :reason =>
                'def legal?(tag_lines)
  tokens = split_and_flatten tag_lines
  tokens.each_with_index do |token, index|
    return false if comment?(token) && is_nested_comment?(tokens, index)
  end
  true
end

def split_and_flatten(lines)
  lines.collect { |line| line.split }.flatten
end

def is_nested_comment?(tokens, index)
  tokens_in_front = tokens[0...index]
  tokens_behind = tokens[index + 1..tokens.size]

  tag_in_front = tokens_in_front.any? { |x| tag? x }
  tag_behind = tokens_behind.any? { |x| tag? x }

  tag_in_front && tag_behind
end

def tag?(text)
  if text.match /\A@/
    true
  else
    false
  end
end

def comment?(text)
  if text.match /\A#/
    true
  else
    false
  end
end

if legal? object.tags
  false
else
  true
end'
        },
        :universal_nested_step => {
            :enabled => true,
            :phrase => "A nested step should not universally match all step definitions.  Dead steps cannot be correctly cataloged.",
            :score => FATAL,
            :targets => ["StepDefinition"],
            :reason => "object.nested_steps.each_value do | step_value |
                          modified_step = step_value.gsub(/\\\#{[^}]*}/, '.*')
                          store_rule(object, rule) if modified_step == '.*'
                        end"
        }
    }

    error_rules = {
        :no_description => {
            :enabled => true,
            :phrase => "{class} has no description.",
            :score => ERROR,
            :targets => ["Feature", "Scenario"],
            :reason => "object.name.empty?"
        },
        :no_scenarios => {
            :enabled => true,
            :phrase => "Feature with no scenarios.",
            :score => ERROR,
            :targets => ["Feature"],
            :reason => "object.scenarios.empty?"
        },
        :commented_step => {
            :enabled => true,
            :phrase => "Commented step.",
            :score => ERROR,
            :targets => ["Scenario", "Background"],
            :reason => "object.steps.each do |step|
                          store_rule(object, rule) if is_comment?(step)
                        end"
        },
        :commented_example => {
            :enabled => true,
            :phrase => "Commented example.",
            :score => ERROR,
            :targets => ["Scenario"],
            :reason => "if object.type == 'Scenario Outline'
                          object.examples_table.each {|example| store_rule(object, rule) if is_comment?(example)}
                        end"
        },
        :no_steps => {
            :enabled => true,
            :phrase => "No steps in Scenario.",
            :score => ERROR,
            :targets => ["Scenario", "Background"],
            :reason => "object.steps.empty?"
        },
        :one_word_step => {
            :enabled => true,
            :phrase => "Step that is only one word long.",
            :score => ERROR,
            :targets => ["Scenario", "Background"],
            :reason => "object.steps.each {|step| store_rule(object, rule) if step.split.count == 2}"
        },
        :no_code => {
            :enabled => true,
            :phrase => "No code in Step Definition.",
            :score => ERROR,
            :targets => ["StepDefinition"],
            :reason => "object.code.empty?"
        },
        :around_hook_without_2_parameters => {
            :enabled => true,
            :phrase => "Around hook without 2 parameters for Scenario and Block.",
            :score => ERROR,
            :targets => ["Hook"],
            :reason => "object.type == \"Around\" and object.parameters.count != 2"
        },
        :around_hook_no_block_call => {
            :enabled => true,
            :phrase => "Around hook does not call its block.",
            :score => ERROR,
            :targets => ["Hook"],
            :reason => "flag = true
                        flag = false if object.type != 'Around'
                        block_call = \"\#{object.parameters[1]}.call\"
                          object.code.each do |line|
                            if line.include?(block_call)
                              flag = false
                              break
                            end
                          end
                        flag"
        },
        :hook_no_debugging => {
            :enabled => true,
            :phrase => "Hook without a begin/rescue. Reduced visibility when debugging.",
            :score => ERROR,
            :targets => ["Hook"],
            :reason => "(object.code.empty? != true and object.code.join.match(/.*begin.*rescue.*/).nil?)"

        },
        :hook_conflicting_tags => {
            :enabled => true,
            :phrase => "Hook that both expects and ignores the same tag. This hook will not function as expected.",
            :score => ERROR,
            :targets => ["Hook"],
            :reason => "all_tags = []
                        object.tags.each { |single_tag| all_tags << single_tag.split(',') }
                        all_tags.flatten!
                        flag = false
                        all_tags.each do |single_tag|
                          tag = single_tag.gsub(\"~\", \"\")
                          if all_tags.include?(tag) and all_tags.include?(\"~\#{tag}\")
                            flag =  true
                            break
                          end
                        end
                        flag
                        "
        },
    }

    warning_rules = {
        :numbers_in_description => {
            :enabled => true,
            :phrase => "{class} has numbers in the description.",
            :score => WARNING,
            :targets => ["Feature", "Scenario", "Background"],
            :reason => "!(object.name =~ /\\d+/).nil?"
        },
        :empty_feature => {
            :enabled => true,
            :phrase => "Feature file has no content.",
            :score => WARNING,
            :targets => ["Feature"],
            :reason => "object.feature_lines == []"
        },
        :background_with_no_scenarios => {
            :enabled => true,
            :phrase => "Feature has a background with no scenarios.",
            :score => WARNING,
            :targets => ["Feature"],
            :reason => "object.scenarios.empty? and !object.background.nil?"
        },
        :background_with_one_scenario => {
            :enabled => true,
            :phrase => "Feature has a background with one scenario.",
            :score => WARNING,
            :targets => ["Feature"],
            :reason => "object.scenarios.size == 1 and !object.background.nil?"
        },
        :too_many_steps => {
            :enabled => true,
            :phrase => "{class} with too many steps.",
            :score => WARNING,
            :max => 7,
            :targets => ["Scenario", "Background"],
            :reason => "object.steps.count > rule.conditions[:max]"
        },
        :out_of_order_steps => {
            :enabled => true,
            :phrase => "Scenario steps out of Given/When/Then order.",
            :score => WARNING,
            :targets => ["Scenario"],
            :reason => 'step_order = object.get_step_order
                        ["But", "*", "And"].each { |type| step_order.delete(type) }
                        if(step_order != %w(Given When Then) and step_order != %w(When Then))
                          store_rule(object, rule)
                        end'

        },
        :invalid_first_step => {
            :enabled => true,
            :phrase => "Invalid first step. Began with And/But.",
            :score => WARNING,
            :targets => ["Scenario", "Background"],
            :reason => "!(object.steps.first =~ /^\\s*(And|But).*$/).nil?"
        },
        :asterisk_step => {
            :enabled => true,
            :phrase => "Step includes a * instead of Given/When/Then/And/But.",
            :score => WARNING,
            :targets => ["Scenario", "Background"],
            :reason => "object.steps.each do | step |
                          store_rule(object, rule) if( step =~ /^\\s*[*].*$/)
                       end
                       "
        },
        :one_example => {
            :enabled => true,
            :phrase => "Scenario Outline with only one example.",
            :score => WARNING,
            :targets => ["Scenario"],
            :reason => "object.type == 'Scenario Outline' and object.examples_table.size == 2 and !is_comment?(object.examples_table[1])"
        },
        :too_many_examples => {
            :enabled => true,
            :phrase => "Scenario Outline with too many examples.",
            :score => WARNING,
            :max => 10,
            :targets => ["Scenario"],
            :reason => "object.type == 'Scenario Outline' and (object.examples_table.size - 1) >= rule.conditions[:max]"
        },
        :multiple_given_when_then => {
            :enabled => true,
            :phrase => "Given/When/Then used multiple times in the same {class}.",
            :score => WARNING,
            :targets => ["Scenario", "Background"],
            :reason => "
                        step_order = object.get_step_order
                        phrase = rule.phrase.gsub('{class}', type)
                        ['Given', 'When', 'Then'].each {|step_start| store_rule(object, rule, phrase) if step_order.count(step_start) > 1}"
        },
        :too_many_parameters => {
            :enabled => true,
            :phrase => "Too many parameters in Step Definition.",
            :score => WARNING,
            :max => 4,
            :targets => ["StepDefinition"],
            :reason => "object.parameters.size > rule.conditions[:max]"

        },
        :lazy_debugging => {
            :enabled => true,
            :phrase => "Lazy Debugging through puts, p, or print",
            :score => WARNING,
            :targets => ["StepDefinition"],
            :reason => "object.code.each {|line| store_rule(object, rule) if line.strip =~ /^(p|puts)( |\\()('|\\\"|%(q|Q)?\\{)/}"
        },
        :pending => {
            :enabled => true,
            :phrase => "Pending step definition. Implement or remove.",
            :score => WARNING,
            :targets => ["StepDefinition"],
            :reason => "object.code.each {|line|
                          if line =~ /^\\s*pending(\\(.*\\))?(\\s*[#].*)?$/
                            store_rule(object, rule)
                            break
                          end
                        }"
        },
        :feature_same_tag => {
            :enabled => true,
            :phrase => "Same tag appears on Feature.",
            :score => WARNING,
            :targets => ["Feature"],
            :reason => 'if(object.scenarios.count >= 2)
                          object.scenarios[1..-1].each do |scenario|
                            object.scenarios.first.tags.each do |tag|
                              store_rule(object, rule) if scenario.tags.include?(tag)
                            end
                          end
                        end'
        },
        :scenario_same_tag => {
            :enabled => true,
            :phrase => "Tag appears on all scenarios.",
            :score => WARNING,
            :targets => ["Feature"],
            #TODO really hacky
            :reason => "unless object.scenarios.empty?
                          base_tag_list = object.scenarios.first.tags.clone
                          object.scenarios.each do |scenario|
                            base_tag_list.each do |tag|
                              base_tag_list.delete(tag) unless scenario.tags.include?(tag)
                            end
                          end
                          base_tag_list.count.times { store_rule(object, rule) }
                        end"
        },
        :commas_in_description => {
            :enabled => true,
            :phrase => "There are commas in the description, creating possible multirunning scenarios or features.",
            :score => WARNING,
            :targets => ["Feature", "Scenario"],
            :reason => 'object.name.include?(",")'
        },
        :commented_tag => {
            :enabled => true,
            :phrase => "{class} has a commented out tag",
            :score => WARNING,
            :targets => ["Feature", "Scenario"],
            :reason => 'object.tags.each do | tag |
                          store_rule(object, rule, rule.phrase.gsub("{class}", type)) if is_comment?(tag)
                        end'
        },
        :empty_hook => {
            :enabled => true,
            :phrase => "Hook with no content.",
            :score => WARNING,
            :targets => ["Hook"],
            :reason => "object.code == []"
        },
        :hook_all_comments => {
            :enabled => true,
            :phrase => "Hook is only comments.",
            :score => WARNING,
            :targets => ["Hook"],
            :reason => "flag = true
                        object.code.each do |line|
                          flag = false if line.match(/^\\s*\\#.*$/).nil?
                        end
                        flag"
        },
        :hook_duplicate_tags => {
            :enabled => true,
            :phrase => "Hook has duplicate tags.",
            :score => WARNING,
            :targets => ["Hook"],
            :reason => "all_tags = []
                        object.tags.each { |single_tag| all_tags << single_tag.split(',') }
                        all_tags.flatten!
                        unique_tags = all_tags.uniq
                        true unless all_tags == unique_tags"
        }
    }

    info_rules = {
        :too_many_tags => {
            :enabled => true,
            :phrase => "{class} has too many tags.",
            :score => INFO,
            :max => 8,
            :targets => ["Feature", "Scenario"],
            :reason => "object.tags.size >= rule.conditions[:max]"
        },
        :long_name => {
            :enabled => true,
            :phrase => "{class} has a long description.",
            :score => INFO,
            :max => 180,
            :targets => ["Feature", "Scenario", "Background"],
            :reason => "object.name.length >= rule.conditions[:max]"
        },
        :implementation_word => {
            :enabled => true,
            :phrase => "Implementation word used: {word}.",
            :score => INFO,
            :words => ["page", "site", "url", "drop down", "dropdown", "select list", "click", "text box", "radio button", "check box", "xml", "window", "pop up", "pop-up", "screen", "tab", "database", "DB"],
            :targets => ["Scenario", "Background"],
            :reason => "object.steps.each do |step|
                          next if is_comment?(step)
                          rule.conditions[:words].each do |word|
                            new_phrase = rule.phrase.gsub(/{.*}/, word)
                            store_rule(object, rule, new_phrase) if step.include?(word)
                          end
                        end"

        },
        :implementation_word_button => {
            :enabled => true,
            :phrase => "Implementation word used: button.",
            :score => INFO,
            :targets => ["Scenario"],
            :reason => "object.steps.each do |step|
                          matches = step.match(/(?<prefix>\\w+)\\sbutton/i)
                          if(!matches.nil? and matches[:prefix].downcase != 'radio')
                            store_rule(object, rule)
                          end
                        end"

        },:too_many_scenarios => {
            :enabled => true,
            :phrase => "Feature with too many scenarios.",
            :score => INFO,
            :max => 10,
            :targets => ["Feature"],
            :reason => "object.scenarios.size >= rule.conditions[:max]"
        },
        :date_used => {
            :enabled => true,
            :phrase => "Date used.",
            :score => INFO,
            :targets => ["Scenario", "Background"],
            :reason => "object.steps.each {|step| store_rule(object, rule) if step =~ DATE_REGEX}"
        },
        :nested_step => {
            :enabled => true,
            :phrase => "Nested step call.",
            :score => INFO,
            :targets => ["StepDefinition"],
            :reason => "!object.nested_steps.empty?"
        },
        :commented_code => {
            :enabled => true,
            :phrase => "Commented code in Step Definition.",
            :score => INFO,
            :targets => ["StepDefinition"],
            :reason => "object.code.each {|line| store_rule(object, rule) if is_comment?(line)}"
        },
        :small_sleep => {
            :enabled => true,
            :phrase => "Small sleeps used. Use a wait_until like method.",
            :score => INFO,
            :max => 2,
            :targets => ["StepDefinition"],
            :reason => "object.code.each do |line|
                          match_data = line.match /^\\s*sleep(\\s|\\()(?<sleep_time>.*)\\)?/
                          if match_data
                            sleep_value = match_data[:sleep_time].to_f
                            store_rule(object, rule) if sleep_value < rule.conditions[:max]
                          end
                        end"
        },
        :large_sleep => {
            :enabled => true,
            :phrase => "Large sleeps used. Use a wait_until like method.",
            :score => INFO,
            :min => 2,
            :targets => ["StepDefinition"],
            :reason => "object.code.each do |line|
                          match_data = line.match /^\\s*sleep(\\s|\\()(?<sleep_time>.*)\\)?/
                          if match_data
                            sleep_value = match_data[:sleep_time].to_f
                            store_rule(object, rule) if sleep_value > rule.conditions[:min]
                          end
                        end"
        },
        :todo => {
            :enabled => true,
            :phrase => "Todo found. Resolve it.",
            :score => INFO,
            :targets => ["StepDefinition"],
            :reason => "object.code.each {|line| store_rule(object, rule) if line =~ /\\#(TODO|todo)/}
                        false"
        },
        :hook_not_in_hooks_file => {
            :enabled => true,
            :phrase => "Hook found outside of the designated hooks file",
            :score => INFO,
            :file => "hooks.rb",
            :targets => ["Hook"],
            :reason => "object.location.include?(rule.conditions[:file]) != true"
        },
    }

    # Master hash used for rule data
    # * +:enabled+
    # * +:phrase+
    # * +:score+
    # * +:targets+
    # * +:reason+
    # Optional:
    # * +:words+
    # * +:max+
    # * +:min+
    # * +:file+
    RULES = {}.merge fatal_rules.merge error_rules.merge warning_rules.merge info_rules
  end
end
