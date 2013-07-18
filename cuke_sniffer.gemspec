Gem::Specification.new do |s|
  s.name = 'cuke_sniffer'
  s.version = '0.0.6'
  s.date = '2013-08-15'
  s.summary = "CukeSniffer"
  s.description = "A ruby library used to root out smells in your cukes."
  s.authors = ["Robert Cochran", "Chris Vaughn", "Robert Anderson"]
  s.email = "cochrarj@miamioh.edu"
  s.files = ["lib/cuke_sniffer.rb",
             "lib/cuke_sniffer/constants.rb",
             "lib/cuke_sniffer/feature.rb",
             "lib/cuke_sniffer/feature_rules_evaluator.rb",
             "lib/cuke_sniffer/rule_target.rb",
             "lib/cuke_sniffer/rule_config.rb",
             "lib/cuke_sniffer/scenario.rb",
             "lib/cuke_sniffer/step_definition.rb",
             "lib/cuke_sniffer/report/markup.html.erb",
             "lib/cuke_sniffer/report/rules.html.erb",
             "lib/cuke_sniffer/rule.rb",
             "lib/cuke_sniffer/summary_node.rb",
             "lib/cuke_sniffer/rules_evaluator.rb",
             "lib/cuke_sniffer/cli.rb",
             "lib/cuke_sniffer/hook.rb",
             "bin/cuke_sniffer"
  ]
  s.license = 'MIT'
  s.homepage = 'https://github.com/r-cochran/cuke_sniffer'
  s.add_runtime_dependency 'roxml'
  s.executables = ["cuke_sniffer"]
end
