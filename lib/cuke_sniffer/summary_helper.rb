module CukeSniffer
  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Mixins: CukeSniffer::Constants
  class SummaryHelper
    include CukeSniffer::Constants

    def self.sort_improvement_list(improvement_list)
      sorted_array = improvement_list.sort_by { |improvement, occurrence| occurrence }.reverse
      sorted_improvement_list = {}
      sorted_array.reverse.each { |node|
        sorted_improvement_list[node[0]] = node[1]
      }
      sorted_improvement_list
    end

    def self.make_assessment_hash
      {
          :total => 0,
          :total_score => 0,
          :min => nil,
          :min_file => nil,
          :max => nil,
          :max_file => nil,
          :average => 0,
          :threshold => nil,
          :good => 0,
          :bad => 0,
          :improvement_list => {}
      }
    end

    def self.initialize_assessment_hash(rule_target_list, type)
      assessment_hash = make_assessment_hash
      assessment_hash[:total] = rule_target_list.count
      assessment_hash[:threshold] = THRESHOLDS[type]

      unless rule_target_list.empty?
        score = rule_target_list.first.score
        location = rule_target_list.first.location
        assessment_hash[:min] = score
        assessment_hash[:min_file] = location
        assessment_hash[:max] = score
        assessment_hash[:max_file] = location
      end
      assessment_hash
    end

    def self.assess_rule_target_list(rule_target_list, type)
      assessment_hash = initialize_assessment_hash(rule_target_list, type)
      rule_target_list.each do |rule_target|
        score = rule_target.score
        assessment_hash[:total_score] += score
        assessment_hash[rule_target.good? ? :good : :bad] += 1
        if score < assessment_hash[:min]
          assessment_hash[:min] = score
          assessment_hash[:min_file] = rule_target.location
        end
        if score > assessment_hash[:max]
          assessment_hash[:max] = score
          assessment_hash[:max_file] = rule_target.location
        end
        rule_target.rules_hash.each_key do |key|
          assessment_hash[:improvement_list][key] ||= 0
          assessment_hash[:improvement_list][key] += rule_target.rules_hash[key]
        end
      end
      assessment_hash[:average] = (assessment_hash[:total_score].to_f/rule_target_list.count.to_f).round(2)
      assessment_hash
    end

    def self.load_summary_data(summary_hash)
      summary_node = SummaryNode.new
      summary_node.count = summary_hash[:total]
      summary_node.score = summary_hash[:total_score]
      summary_node.average = summary_hash[:average]
      summary_node.threshold = summary_hash[:threshold]
      summary_node.good = summary_hash[:good]
      summary_node.bad = summary_hash[:bad]
      summary_node
    end

  end
end