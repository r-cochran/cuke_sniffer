require 'roxml'
module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Parent class for all objects that have rules executed against it
  class RulesEvaluator
    include CukeSniffer::Constants
    include ROXML

    xml_accessor :score, :location
    xml_accessor :rules_hash, :as => {:key => "phrase", :value => "score"}, :in => "rules", :from => "rule"

    # int: Sum of the rules fired
    attr_accessor :score

    # hash:
    # * Key: symbol of the rule
    # * Value: times the rule has fired
    attr_accessor :rules_hash

    # Location must be in the format of "file_path\file_name.rb:line_number"
    def initialize(location)
      @location = location
      @score = 0
      @rules_hash = {}
      @class_type = self.class.to_s.gsub(/.*::/, "")
    end

    # Compares the score against the objects threshold
    # If a score is below the threshold it is good and returns true
    # Return: Boolean
    def good?
      score <= Constants::THRESHOLDS[@class_type]
    end

    # Calculates the score to threshold percentage of an object
    # Return: Float
    def problem_percentage
      score.to_f / Constants::THRESHOLDS[@class_type].to_f
    end

    def store_updated_rule(rule, phrase)
      store_rule({:enabled => rule[:enabled], :score => rule[:score], :phrase => phrase})
    end

    def == (comparison_object) # :nodoc:
      comparison_object.location == location &&
      comparison_object.score == score &&
      comparison_object.rules_hash == rules_hash
    end

    private

    def evaluate_score
    end

    def store_rule(rule)
      if rule[:enabled]
        @score += rule[:score]
        @rules_hash[rule[:phrase]] ||= 0
        @rules_hash[rule[:phrase]] += 1
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
end
