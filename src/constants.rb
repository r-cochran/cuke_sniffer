FILE_IGNORE_LIST = %w(. ..)
DATE_REGEX = /(?<date>\d{2}\/\d{2}\/\d{4})/
COMMENT_REGEX = /#?.*/

FEATURE_NAME_REGEX = /Feature:\s*(?<name>.*)/
TAG_REGEX = /(?<tag>@\S*)/
SCENARIO_TITLE_STYLES = /(?<type>Background|Scenario|Scenario Outline|Scenario Template):\s*/
SCENARIO_TITLE_REGEX = /^#{COMMENT_REGEX}#{SCENARIO_TITLE_STYLES}(?<name>.*)/

STEP_STYLES = /(?<style>Given|When|Then|And|Or|But|Transform|\*)\s/
STEP_REGEX = /^#{COMMENT_REGEX}#{STEP_STYLES}(?<step_string>.*)/
STEP_DEFINITION_REGEX = /^#{STEP_STYLES}\/(?<step>.+)\/\sdo\s?(\|(?<parameters>.*)\|)?$/


SIMPLE_NESTED_STEP_REGEX = /^steps\s"#{STEP_STYLES}(?<step_string>.*)"/
SAME_LINE_COMPLEX_STEP_REGEX = /^steps\s%{#{STEP_STYLES}(?<step_string>.*)}/
START_COMPLEX_STEP_REGEX = /^steps\s%{\s*$/
END_COMPLEX_STEP_REGEX = /^}$/
START_COMPLEX_WITH_STEP_REGEX = /^steps\s%{#{STEP_STYLES}(?<step_string>.*)/
END_COMPLEX_WITH_STEP_REGEX = /^#{STEP_STYLES}(?<step_string>.*)}$/