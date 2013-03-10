require 'roxml'
module CukeSniffer
  class RulesEvaluator
    include ROXML
    xml_accessor :score, :location
    xml_accessor :rules_hash, :as => {:key => "phrase", :value => "score"}, :in => "rules", :from => "rule"

    def initialize(location)
      @location = location
      @score = 0
      @rules_hash = {}
      @class_type = self.class.to_s.gsub(/.*::/, "")
    end

    def evaluate_score
    end

    def good?
      score <= Constants::THRESHOLDS[@class_type]
    end

    def problem_percentage
      score.to_f / Constants::THRESHOLDS[@class_type].to_f
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
end
