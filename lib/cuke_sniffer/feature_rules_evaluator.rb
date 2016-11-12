require 'cuke_sniffer/constants'
require 'cuke_sniffer/rule_target'

module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2014 Robert Cochran
  # License::   Distributes under the MIT License
  # Parent class for Feature and Scenario objects
  # holds shared attributes and rules.
  # Extends CukeSniffer::RuleTarget
  class FeatureRuleTarget < RuleTarget

    # string array: Contains all tags attached to a Feature or Scenario
    attr_accessor :tags

    # string: Name of the Feature or Scenario
    attr_accessor :name

    # Location must be in the format of "file_path\file_name.rb:line_number"
    def initialize(location)
      @name = ""
      @tags = []
      super(location)
    end

    def == (comparison_object) # :nodoc:
      super(comparison_object) &&
      comparison_object.name == name &&
      comparison_object.tags == tags
    end

    def commented_tag?(comment)
      # Uncommenting the line in order to more easily try matching a tag
      comment = comment.sub('#', '')

      comment =~ CukeSniffer::Constants::TAG_REGEX
    end

    private

    def create_name(model)
      @name = model.name
      @name += ' ' + model.description.gsub("\n", ' ') unless model.description.empty?
    end

    def update_tag_list(model)
      unless model.is_a?(CukeModeler::Background)
        model.tags.each do |tag|
          @tags << tag.name
        end
      end
    end

  end
end

