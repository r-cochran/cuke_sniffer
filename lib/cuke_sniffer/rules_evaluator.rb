module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Evaluates all cucumber components found in CukeSniffer with the passed rules
  class RulesEvaluator < RuleTarget
    include CukeSniffer::Constants
    attr_accessor :rules

    def initialize(cli, rules)
      raise "A CLI must be provided for evaluation." if cli.nil?
      raise "Rules must be provided for evaluation." if rules.nil? or rules.empty?
      @rules = rules
      judge_features(cli.features)
      judge_objects(cli.step_definitions, "StepDefinition")
      judge_objects(cli.hooks, "Hook")
    end

    private

    def judge_features(features)
      features.each do |feature|
        judge_feature(feature)
      end
    end

    def judge_feature(feature)
      judge_object(feature, "Feature")
      judge_object(feature.background, "Background") unless feature.background.nil?
      judge_objects(feature.scenarios, "Scenario")
      feature.total_score += feature.update_score

    end

    def judge_objects(objects, type)
      objects.each do | object |
        judge_object(object, type)
      end
    end

    def judge_object(object, type)
      @rules.each do |rule|
        fail "No targets for rule: #{rule.phrase}" if rule.targets.nil? or rule.targets.empty?
        next unless rule.targets.include? type and rule.enabled
        if rule.reason.(object, rule, type) == true
          phrase = rule.phrase.gsub("{class}", type)
          store_rule(object, rule, phrase)
        end
      end
    end
  end
end