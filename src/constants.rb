FILE_IGNORE_LIST = %w(. ..)

FEATURE_NAME_REGEX = /Feature:\s*(?<name>.*)/
TAG_REGEX = /(?<tag>@\S*)/
SCENARIO_TITLE_STYLES = /(Scenario|Scenario Outline|Scenario Template):\s*/
SCENARIO_TITLE_REGEX = /#{SCENARIO_TITLE_STYLES}(?<name>.*)/

STEP_STYLES = /(?<style>Given|When|Then|And|Or|But|\*)\s/x
STEP_REGEX = /^#{STEP_STYLES}(?<step_string>.*)/x
STEP_DEFINITION_REGEX = /^#{STEP_STYLES}\/(?<step>.+)\/\sdo\s?(\|(?<parameters>.*)\|)?$/x

SIMPLE_NESTED_STEP_REGEX = /^steps\s"#{STEP_STYLES}(?<step_string>.*)"/x
SAME_LINE_COMPLEX_STEP_REGEX = /^steps\s%{#{STEP_STYLES}(?<step_string>.*)}/x
START_COMPLEX_STEP_REGEX = /^steps\s%{\s*$/
END_COMPLEX_STEP_REGEX = /^}$/
START_COMPLEX_WITH_STEP_REGEX = /^steps\s%{#{STEP_STYLES}(?<step_string>.*)/x
END_COMPLEX_WITH_STEP_REGEX = /^#{STEP_STYLES}(?<step_string>.*)}$/x