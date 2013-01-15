module CukeSniffer
  module Constants
    FILE_IGNORE_LIST = %w(. .. .svn)
    DATE_REGEX = /(?<date>\d{2}\/\d{2}\/\d{4})/
    COMMENT_REGEX = /#?.*/

    FEATURE_NAME_REGEX = /Feature:\s*(?<name>.*)/
    TAG_REGEX = /(?<tag>@\S*)/
    SCENARIO_TITLE_STYLES = /(?<type>Background|Scenario|Scenario Outline|Scenario Template):\s*/
    SCENARIO_TITLE_REGEX = /#{COMMENT_REGEX}#{SCENARIO_TITLE_STYLES}(?<name>.*)/

    STEP_STYLES = /(?<style>Given|When|Then|And|Or|But|Transform|\*)\s/
    STEP_REGEX = /^#{COMMENT_REGEX}#{STEP_STYLES}(?<step_string>.*)/
    STEP_DEFINITION_REGEX = /^#{STEP_STYLES}\/(?<step>.+)\/\sdo\s?(\|(?<parameters>.*)\|)?$/

    SIMPLE_NESTED_STEP_REGEX = /steps\s"#{STEP_STYLES}(?<step_string>.*)"/
    SAME_LINE_COMPLEX_STEP_REGEX = /^steps\s%Q?{#{STEP_STYLES}(?<step_string>.*)}/
    START_COMPLEX_STEP_REGEX = /steps\s%Q?\{\s*/
    END_COMPLEX_STEP_REGEX = /}/
    START_COMPLEX_WITH_STEP_REGEX = /steps\s%Q?\{#{STEP_STYLES}(?<step_string>.*)/
    END_COMPLEX_WITH_STEP_REGEX = /#{STEP_STYLES}(?<step_string>.*)}/

    HELP_CMD_TEXT = "Welcome to CukeSniffer!
Calling CukeSniffer with no arguments will run it against the current directory.
Other Options for Running include:
  <feature_file_path>, <step_def_file_path> : Runs CukeSniffer against the
                                              specified paths.
  -o, --out html (name)                     : Runs CukeSniffer then outputs an
                                              html file in the current
                                              directory (with optional name).
  -h, --help                                : You get this lovely document."

    
  end
end
