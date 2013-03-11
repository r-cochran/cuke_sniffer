Gem::Specification.new do |s|
  s.name = 'cuke_sniffer'
  s.version = '0.0.3'
  s.date = '2013-03-15'
  s.summary = "CukeSniffer"
  s.description = "A ruby library used to root out smells in your cukes."
  s.authors = ["Robert Cochran", "Chris Vaughn", "Robert Anderson"]
  s.files = ["lib/cuke_sniffer.rb",
             "lib/cuke_sniffer/constants.rb",
             "lib/cuke_sniffer/feature.rb",
             "lib/cuke_sniffer/feature_rules_evaluator.rb",
             "lib/cuke_sniffer/rules_evaluator.rb",
             "lib/cuke_sniffer/rule_config.rb",
             "lib/cuke_sniffer/scenario.rb",
             "lib/cuke_sniffer/step_definition.rb",
             "lib/cuke_sniffer/report/markup.rhtml",
             "lib/cuke_sniffer/cli.rb",
             "bin/cuke_sniffer.rb"
             ]
  s.homepage = 'https://github.com/r-cochran/cuke_sniffer'
  s.add_runtime_dependency 'roxml'
  s.executables = ["cuke_sniffer.rb"]
end