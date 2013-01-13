# encoding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))


require 'rspec'

require 'constants'
require 'rule_config'
require 'rules_evaluator'
require 'feature_rules_evaluator'
require 'step_definition'
require 'feature'
require 'scenario'
require 'cuke_sniffer'
