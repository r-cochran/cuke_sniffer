module CukeSniffer
  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # A collection of constants that are used throughout the gem
  module Constants

    FILE_IGNORE_LIST = %w(. .. .svn) # :nodoc:
    DATE_REGEX = /(?<date>\d{2}\/\d{2}\/\d{4})/ # :nodoc:
    COMMENT_REGEX = /#?\s*/ # :nodoc:
    TAG_REGEX = /(^|\s+)(?<tag>@\S*)/ # :nodoc:
    SCENARIO_TITLE_STYLES = /^\s*\#*\s*(?<type>Background|Scenario|Scenario Outline|Scenario Template):\s*/ # :nodoc:
    STEP_STYLES = /(?<style>Given|When|Then|And|Or|But|Transform|\*)\s*/ # :nodoc:
    STEP_REGEX = /^#{COMMENT_REGEX}#{STEP_STYLES}(?<step_string>.*)/ # :nodoc:
    STEP_DEFINITION_REGEX = /^#{STEP_STYLES}[(]?\/(?<step>.+)\/[)]?\sdo\s?(\|(?<parameters>.*)\|)?$/ # :nodoc:
    HOOK_STYLES = /(?<type>Before|After|AfterConfiguration|at_exit|Around|AfterStep)/ # :nodoc:
    HOOK_REGEX = /^#{HOOK_STYLES}(\((?<tags>.*)\)\sdo|\s+do)(\s\|(?<parameters>.*)\|)?/

    MARKUP_SOURCE = File.join(File.dirname(__FILE__), 'report')
    DEFAULT_OUTPUT_FILE_NAME = "cuke_sniffer_result"

    # hash: Stores scores to compare against for determining if an object is good
    # * Key: String of the object name
    #  Project, Feature, Scenario, StepDefinition
    # * Value: Integer of the highest acceptable value an object can have
    # Customizable for a projects level of acceptable score
    #  CukeSniffer::Constants::THRESHOLDS["Project"] = 95000
    THRESHOLDS = {
        "Project" => 1000,
        "Feature" => 30,
        "Scenario" => 30,
        "StepDefinition" => 20,
        "Hook" => 20
    }

  end
end
