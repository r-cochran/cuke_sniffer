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
            :reason => lambda { |scenario, rule| scenario.outline? and scenario.examples_table.size == 1}
        },
        :no_examples_table => {
            :enabled => true,
            :phrase => "Scenario Outline with no examples table.",
            :score => FATAL,
            :targets => ["Scenario"],
            :reason => lambda { |scenario, rule| scenario.outline? and scenario.examples_table.empty?}
        },
        :recursive_nested_step => {
            :enabled => true,
            :phrase => "Recursive nested step call.",
            :score => FATAL,
            :targets => ["StepDefinition"],
            :reason => lambda { |step_definition, rule| step_definition.store_rule_many_times(rule, step_definition.recursive_nested_steps.size)}
        },
        :background_with_tag => {
            :enabled => true,
            :phrase => "There is a background with a tag. This feature file cannot run!",
            :score => FATAL,
            :targets => ["Background"],
            :reason =>  lambda { |background, rule| background.tags.size > 0}
        },
        :comment_after_tag => {
            :enabled => true,
            :phrase => "Comment comes between tag and properly executing line. This feature file cannot run!",
            :score => FATAL,
            :targets => ["Feature", "Scenario"],
            :reason =>
                lambda { |feature_rule_target, rule|
                  tokens = feature_rule_target.tags.collect { |line| line.split }.flatten

                  tokens.each_with_index do |token, index|
                    if feature_rule_target.is_comment?(token) && tokens[0...index].any? { |x| x =~ /\A@/ }
                      return feature_rule_target.store_rule(rule)
                    end
                  end
                }
        },
        :universal_nested_step => {
            :enabled => true,
            :phrase => "A nested step should not universally match all step definitions.  Dead steps cannot be correctly cataloged.",
            :score => FATAL,
            :targets => ["StepDefinition"],
            :reason => lambda { |step_definition, rule| step_definition.nested_steps.each_value do | step_value |
                          modified_step = step_value.gsub(/\#{[^}]*}/, '.*')
                          step_definition.store_rule(rule) if modified_step == '.*'
                        end}
        }
    }

    error_rules = {
        :no_description => {
            :enabled => true,
            :phrase => "{class} has no description.",
            :score => ERROR,
            :targets => ["Feature", "Scenario"],
            :reason => lambda { |feature_rule_target, rule| feature_rule_target.name.empty?}
        },
        :no_scenarios => {
            :enabled => true,
            :phrase => "Feature with no scenarios.",
            :score => ERROR,
            :targets => ["Feature"],
            :reason => lambda { |feature, rule| feature.scenarios.empty?}
        },
        :commented_step => {
            :enabled => true,
            :phrase => "Commented step.",
            :score => ERROR,
            :targets => ["Scenario", "Background"],
            :reason =>  lambda { |scenario, rule| scenario.steps.each do |step|
                          scenario.store_rule(rule) if scenario.is_comment?(step)
                        end}
        },
        :commented_example => {
            :enabled => true,
            :phrase => "Commented example.",
            :score => ERROR,
            :targets => ["Scenario"],
            :reason =>  lambda { |scenario, rule| scenario.store_rule_many_times(rule, scenario.commented_examples.size) }
        },
        :no_steps => {
            :enabled => true,
            :phrase => "No steps in Scenario.",
            :score => ERROR,
            :targets => ["Scenario", "Background"],
            :reason => lambda { |scenario, rule| scenario.steps.empty?}
        },
        :one_word_step => {
            :enabled => true,
            :phrase => "Step that is only one word long.",
            :score => ERROR,
            :targets => ["Scenario", "Background"],
            :reason => lambda { |scenario, rule| scenario.steps.each {|step| scenario.store_rule(rule) if step.split.count == 2}}
        },
        :no_code => {
            :enabled => true,
            :phrase => "No code in Step Definition.",
            :score => ERROR,
            :targets => ["StepDefinition"],
            :reason => lambda { |step_definition, rule| step_definition.code.empty?}
        },
        :around_hook_without_2_parameters => {
            :enabled => true,
            :phrase => "Around hook without 2 parameters for Scenario and Block.",
            :score => ERROR,
            :targets => ["Hook"],
            :reason => lambda { |hook, rule| hook.around? and hook.parameters.count != 2}
        },
        :around_hook_no_block_call => {
            :enabled => true,
            :phrase => "Around hook does not call its block.",
            :score => ERROR,
            :targets => ["Hook"],
            :reason => lambda { |hook, rule| hook.around? and !hook.calls_block?}
        },
        :hook_no_debugging => {
            :enabled => true,
            :phrase => "Hook without a begin/rescue. Reduced visibility when debugging.",
            :score => ERROR,
            :targets => ["Hook"],
            :reason => lambda { |hook, rule| (hook.code.empty? != true and hook.code.join.match(/.*begin.*rescue.*/).nil?)}

        },
        :hook_conflicting_tags => {
            :enabled => true,
            :phrase => "Hook that both expects and ignores the same tag. This hook will not function as expected.",
            :score => ERROR,
            :targets => ["Hook"],
            :reason => lambda { |hook, rule| hook.conflicting_tags? }
        },
    }

    warning_rules = {
        :numbers_in_description => {
            :enabled => true,
            :phrase => "{class} has numbers in the description.",
            :score => WARNING,
            :targets => ["Feature", "Scenario", "Background"],
            :reason => lambda { |feature_rule_target, rule| !(feature_rule_target.name =~ /\d+/).nil?}
        },
        :empty_feature => {
            :enabled => true,
            :phrase => "Feature file has no content.",
            :score => WARNING,
            :targets => ["Feature"],
            :reason => lambda { |feature, rule| feature.feature_lines == []}
        },
        :background_with_no_scenarios => {
            :enabled => true,
            :phrase => "Feature has a background with no scenarios.",
            :score => WARNING,
            :targets => ["Feature"],
            :reason => lambda { |feature, rule| feature.scenarios.empty? and !feature.background.nil?}
        },
        :background_with_one_scenario => {
            :enabled => true,
            :phrase => "Feature has a background with one scenario.",
            :score => WARNING,
            :targets => ["Feature"],
            :reason => lambda { |feature, rule| feature.scenarios.size == 1 and !feature.background.nil?}
        },
        :too_many_steps => {
            :enabled => true,
            :phrase => "{class} with too many steps.",
            :score => WARNING,
            :max => 7,
            :targets => ["Scenario", "Background"],
            :reason => lambda { |scenario, rule| scenario.steps.count > rule.conditions[:max]}
        },
        :out_of_order_steps => {
            :enabled => true,
            :phrase => "Scenario steps out of Given/When/Then order.",
            :score => WARNING,
            :targets => ["Scenario"],
            :reason => lambda { |scenario, rule| step_order = scenario.get_step_order
                        ["But", "*", "And"].each { |type| step_order.delete(type) }
                        if(step_order != %w(Given When Then) and step_order != %w(When Then))
                          scenario.store_rule(rule)
                        end}

        },
        :invalid_first_step => {
            :enabled => true,
            :phrase => "Invalid first step. Began with And/But.",
            :score => WARNING,
            :targets => ["Scenario", "Background"],
            :reason => lambda { |scenario, rule| !(scenario.steps.first =~ /^\s*(And|But).*$/).nil?}
        },
        :asterisk_step => {
            :enabled => true,
            :phrase => "Step includes a * instead of Given/When/Then/And/But.",
            :score => WARNING,
            :targets => ["Scenario", "Background"],
            :reason => lambda { |scenario, rule| scenario.steps.each do | step |
                          scenario.store_rule(rule) if( step =~ /^\s*[*].*$/)
                       end
            }
        },
        :one_example => {
            :enabled => true,
            :phrase => "Scenario Outline with only one example.",
            :score => WARNING,
            :targets => ["Scenario"],
            :reason => lambda { |scenario, rule| scenario.outline? and scenario.examples_table.size == 2 and !scenario.is_comment?(scenario.examples_table[1])}
        },
        :too_many_examples => {
            :enabled => true,
            :phrase => "Scenario Outline with too many examples.",
            :score => WARNING,
            :max => 10,
            :targets => ["Scenario"],
            :reason => lambda { |scenario, rule| scenario.outline? and (scenario.examples_table.size - 1) >= rule.conditions[:max]}
        },
        :multiple_given_when_then => {
            :enabled => true,
            :phrase => "Given/When/Then used multiple times in the same {class}.",
            :score => WARNING,
            :targets => ["Scenario", "Background"],
            :reason => lambda { |scenario, rule|
                        step_order = scenario.get_step_order
                        phrase = rule.phrase.gsub('{class}', scenario.type)
                        ['Given', 'When', 'Then'].each {|step_start| scenario.store_rule(rule, phrase) if step_order.count(step_start) > 1}}
        },
        :too_many_parameters => {
            :enabled => true,
            :phrase => "Too many parameters in Step Definition.",
            :score => WARNING,
            :max => 4,
            :targets => ["StepDefinition"],
            :reason => lambda { |step_definition, rule| step_definition.parameters.size > rule.conditions[:max]}

        },
        :lazy_debugging => {
            :enabled => true,
            :phrase => "Lazy Debugging through puts, p, or print",
            :score => WARNING,
            :targets => ["StepDefinition"],
            :reason => lambda { |step_definition, rule| step_definition.code.each {|line| step_definition.store_rule(rule) if line.strip =~ /^(p|puts)( |\()('|"|%(q|Q)?\{)/}}
        },
        :pending => {
            :enabled => true,
            :phrase => "Pending step definition. Implement or remove.",
            :score => WARNING,
            :targets => ["StepDefinition"],
            :reason => lambda { |step_definition, rule| step_definition.code.each {|line|
                          if line =~ /^\s*pending(\(.*\))?(\s*[#].*)?$/
                            step_definition.store_rule(rule)
                            break
                          end
                        }}
        },
        :feature_same_tag => {
            :enabled => true,
            :phrase => "Same tag appears on Feature.",
            :score => WARNING,
            :targets => ["Feature"],
            :reason => lambda { |feature, rule| if(feature.scenarios.count >= 2)
                          feature.scenarios[1..-1].each do |scenario|
                            feature.scenarios.first.tags.each do |tag|
                              feature.store_rule(rule) if scenario.tags.include?(tag)
                            end
                          end
                        end}
        },
        :scenario_same_tag => {
            :enabled => true,
            :phrase => "Tag appears on all scenarios.",
            :score => WARNING,
            :targets => ["Feature"],
            #TODO really hacky
            :reason => lambda { |feature, rule| unless feature.scenarios.empty?
                          base_tag_list = feature.scenarios.first.tags.clone
                          feature.scenarios.each do |scenario|
                            base_tag_list.each do |tag|
                              base_tag_list.delete(tag) unless scenario.tags.include?(tag)
                            end
                          end
                          base_tag_list.count.times { feature.store_rule(rule) }
                        end}
        },
        :commas_in_description => {
            :enabled => true,
            :phrase => "There are commas in the description, creating possible multirunning scenarios or features.",
            :score => WARNING,
            :targets => ["Feature", "Scenario"],
            :reason => lambda { |rule_target, rule| rule_target.name.include?(",")}
        },
        :commented_tag => {
            :enabled => true,
            :phrase => "{class} has a commented out tag",
            :score => WARNING,
            :targets => ["Feature", "Scenario"],
            :reason => lambda { |feature_rule_target, rule| feature_rule_target.tags.each do | tag |
                          feature_rule_target.store_rule(rule, rule.phrase.gsub("{class}", feature_rule_target.type)) if feature_rule_target.is_comment?(tag)
                        end}
        },
        :empty_hook => {
            :enabled => true,
            :phrase => "Hook with no content.",
            :score => WARNING,
            :targets => ["Hook"],
            :reason => lambda { |hook, rule| hook.code == []}
        },
        :hook_all_comments => {
            :enabled => true,
            :phrase => "Hook is only comments.",
            :score => WARNING,
            :targets => ["Hook"],
            :reason => lambda { |hook, rule| flag = true
                        hook.code.each do |line|
                          flag = false if line.match(/^\s*#.*$/).nil?
                        end
                        flag}
        },
        :hook_duplicate_tags => {
            :enabled => true,
            :phrase => "Hook has duplicate tags.",
            :score => WARNING,
            :targets => ["Hook"],
            :reason => lambda { |hook, rule|
                        all_tags = []
                        hook.tags.each { |single_tag| all_tags << single_tag.split(',') }
                        all_tags.flatten!
                        unique_tags = all_tags.uniq
                        true unless all_tags == unique_tags}
        }
    }

    info_rules = {
        :too_many_tags => {
            :enabled => true,
            :phrase => "{class} has too many tags.",
            :score => INFO,
            :max => 8,
            :targets => ["Feature", "Scenario"],
            :reason => lambda { |feature_rule_target, rule| feature_rule_target.tags.size >= rule.conditions[:max]}
        },
        :long_name => {
            :enabled => true,
            :phrase => "{class} has a long description.",
            :score => INFO,
            :max => 180,
            :targets => ["Feature", "Scenario", "Background"],
            :reason => lambda { |feature_rule_target, rule| feature_rule_target.name.length >= rule.conditions[:max]}
        },
        :implementation_word => {
            :enabled => true,
            :phrase => "Implementation word used: {word}.",
            :score => INFO,
            :words => ["page", "site", "url", "drop down", "dropdown", "select list", "click", "text box", "radio button", "check box", "xml", "window", "pop up", "pop-up", "screen", "database", "DB"],
            :targets => ["Scenario", "Background"],
            :reason => lambda { |scenario, rule| scenario.steps.each do |step|
                          next if scenario.is_comment?(step)
                          rule.conditions[:words].each do |word|
                            new_phrase = rule.phrase.gsub(/{.*}/, word)
                            scenario.store_rule(rule, new_phrase) if step.include?(word)
                          end
                        end}

        },
        :implementation_word_button => {
            :enabled => true,
            :phrase => "Implementation word used: button.",
            :score => INFO,
            :targets => ["Scenario"],
            :reason => lambda { |scenario, rule| scenario.steps.each do |step|
                          matches = step.match(/(?<prefix>\w+)\sbutton/i)
                          if(!matches.nil? and matches[:prefix].downcase != 'radio')
                            scenario.store_rule(rule)
                          end
                        end}

        },
        :implementation_word_tab => {
            :enabled => true,
            :phrase => "Implementation word used: tab.",
            :score => INFO,
            :targets => ["Scenario"],
            :reason => lambda { |scenario, rule| scenario.steps.each do |step|
              scenario.store_rule(rule) if (step.split.include?("tab"))
            end}
        },
        :too_many_scenarios => {
            :enabled => true,
            :phrase => "Feature with too many scenarios.",
            :score => INFO,
            :max => 10,
            :targets => ["Feature"],
            :reason => lambda { |feature, rule| feature.scenarios.size >= rule.conditions[:max]}
        },
        :date_used => {
            :enabled => true,
            :phrase => "Date used.",
            :score => INFO,
            :targets => ["Scenario", "Background"],
            :reason => lambda { |scenario, rule| scenario.steps.each {|step| scenario.store_rule(rule) if step =~ CukeSniffer::Constants::DATE_REGEX}}
        },
        :nested_step => {
            :enabled => true,
            :phrase => "Nested step call.",
            :score => INFO,
            :targets => ["StepDefinition"],
            :reason => lambda { |step_definition, rule| !step_definition.nested_steps.empty?}
        },
        :commented_code => {
            :enabled => true,
            :phrase => "Commented code in Step Definition.",
            :score => INFO,
            :targets => ["StepDefinition"],
            :reason => lambda { |step_definition, rule| step_definition.code.each {|line| step_definition.store_rule(rule) if step_definition.is_comment?(line)}}
        },
        :small_sleep => {
            :enabled => true,
            :phrase => "Small sleeps used. Use a wait_until like method.",
            :score => INFO,
            :max => 2,
            :targets => ["StepDefinition"],
            :reason => lambda { |step_definition, rule| step_definition.code.each do |line|
                          match_data = line.match /^\s*sleep(\s|\()(?<sleep_time>.*)\)?/
                          if match_data
                            sleep_value = match_data[:sleep_time].to_f
                            step_definition.store_rule(rule) if sleep_value < rule.conditions[:max]
                          end
                        end}
        },
        :large_sleep => {
            :enabled => true,
            :phrase => "Large sleeps used. Use a wait_until like method.",
            :score => INFO,
            :min => 2,
            :targets => ["StepDefinition"],
            :reason => lambda { |step_definition, rule| step_definition.code.each do |line|
                          match_data = line.match /^\s*sleep(\s|\()(?<sleep_time>.*)\)?/
                          if match_data
                            sleep_value = match_data[:sleep_time].to_f
                            step_definition.store_rule(rule) if sleep_value > rule.conditions[:min]
                          end
                        end}
        },
        :todo => {
            :enabled => true,
            :phrase => "Todo found. Resolve it.",
            :score => INFO,
            :targets => ["StepDefinition"],
            :reason => lambda { |step_definition, rule| step_definition.code.each {|line| step_definition.store_rule(rule) if line =~ /#(TODO|todo)/}
                        false}
        },
        :hook_not_in_hooks_file => {
            :enabled => true,
            :phrase => "Hook found outside of the designated hooks file",
            :score => INFO,
            :file => "hooks.rb",
            :targets => ["Hook"],
            :reason => lambda { |hook, rule| hook.location.include?(rule.conditions[:file]) != true}
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
