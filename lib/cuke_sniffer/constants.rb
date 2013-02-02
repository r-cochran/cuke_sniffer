module CukeSniffer
  module Constants
    FILE_IGNORE_LIST = %w(. .. .svn)
    DATE_REGEX = /(?<date>\d{2}\/\d{2}\/\d{4})/
    COMMENT_REGEX = /#?\s*/

    TAG_REGEX = /(?<tag>@\S*)/

    SCENARIO_TITLE_STYLES = /(?<type>Background|Scenario|Scenario Outline|Scenario Template):\s*/

    STEP_STYLES = /(?<style>Given|When|Then|And|Or|But|Transform|\*)\s/
    STEP_REGEX = /^#{COMMENT_REGEX}#{STEP_STYLES}(?<step_string>.*)/
    STEP_DEFINITION_REGEX = /^#{STEP_STYLES}\/(?<step>.+)\/\sdo\s?(\|(?<parameters>.*)\|)?$/

    THRESHOLDS = {
        "Project" => 1000,
        "Feature" => 30,
        "Scenario" => 30,
        "StepDefinition" => 20
    }
  end
end
