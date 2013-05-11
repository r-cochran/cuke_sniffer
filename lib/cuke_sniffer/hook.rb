require 'roxml'
module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Cucumber Hook class used for evaluating rules
  # Extends CukeSniffer::RulesEvaluator
  class Hook < RulesEvaluator

    xml_accessor :start_line
    xml_accessor :type
    xml_accessor :tags, :as => [], :in => "tags"
    xml_accessor :parameters, :as => [], :in => "parameters"
    xml_accessor :code, :as => [], :in => "code"

    # The type of the hook: AfterConfiguration, After, AfterStep, Around, Before, at_exit
    attr_accessor :type

    # The list of tags used as a filter for the hook
    attr_accessor :tags

    # The parameters that are declared on the hook
    attr_accessor :parameters

    # Integer of the line in which the hook was found
    attr_accessor :start_line

    # Array of strings that contain the code kept in the hook
    attr_accessor :code


    # location must be in the format of "file_path\file_name.rb:line_number"
    # raw_code is an array of strings that represents the step definition
    # must contain the hook declaration line and the pairing end
    def initialize(location, raw_code)
      super(location)

      @start_line = location.match(/:(?<line>\d*)$/)[:line].to_i
      @type = nil
      @tags = []
      @parameters = []

      end_match_index = (raw_code.size - 1) - raw_code.reverse.index("end")
      @code = raw_code[1...end_match_index]

      raw_code.each do |line|
        if line =~ HOOK_REGEX
          matches = HOOK_REGEX.match(line)
          @type = matches[:type]
          hook_tag_regexp = /["']([^"']*)["']/
          matches[:tags].scan(hook_tag_regexp).each { |tag| @tags << tag[0] } if matches[:tags]
          @parameters = matches[:parameters].split(/,\s*/) if matches[:parameters]
        end
      end
      evaluate_score
    end

    def ==(comparison_object) # :nodoc:
      super(comparison_object) &&
          comparison_object.type == type &&
          comparison_object.tags == tags &&
          comparison_object.parameters == parameters &&
          comparison_object.code == code
    end

    private

    def evaluate_score
      rule_empty_hook
      rule_hook_not_in_hooks_file
      rule_no_debugging
      rule_all_comments
      if @type == "Around"
        rule_around_hook_without_2_parameters
        rule_around_hook_no_block_call
      end
    end

    def rule_empty_hook
      rule = RULES[:empty_hook]
      store_rule(rule) if @code == []
    end

    def rule_hook_not_in_hooks_file
      rule = RULES[:hook_not_in_hooks_file]
      store_rule(rule) unless @location.include?(rule[:file])
    end

    def rule_around_hook_without_2_parameters
      rule = RULES[:around_hook_without_2_parameters]
      store_rule(rule) unless @parameters.count == 2
    end

    def rule_around_hook_no_block_call
      return if @rules_hash.keys.include?(RULES[:around_hook_without_2_parameters][:phrase])
      rule = RULES[:around_hook_no_block_call]
      block_call = "#{@parameters[1]}.call"
      @code.each do |line|
        return if line.include?(block_call)
      end
      store_rule(rule)
    end

    def rule_no_debugging
      rule = RULES[:hook_no_debugging]
      begin_found = false
      rescue_found = false
      @code.each do |line|
        begin_found = true if line.include?("begin")
        rescue_found = true if line.include?("rescue")
        break if begin_found and rescue_found
      end
      store_rule(rule) unless begin_found and rescue_found
    end

    def rule_all_comments
      rule = RULES[:hook_all_comments]
      @code.each do |line|
        return unless is_comment?(line)
      end
      store_rule(rule)
    end

  end
end
