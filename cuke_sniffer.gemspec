Gem::Specification.new do |s|
  s.name = 'cuke_sniffer'
  s.version = '0.0.7'
  s.date = '2013-10-01'
  s.summary = "CukeSniffer"
  s.description = "A ruby library used to root out smells in your cukes."
  s.authors = ["Robert Cochran", "Chris Vaughn", "Robert Anderson"]
  s.email = "cochrarj@miamioh.edu"
  s.files = ["lib/cuke_sniffer/report/dead_steps.html.erb",
             "lib/cuke_sniffer/report/js.html.erb",
             "lib/cuke_sniffer/report/css.html.erb",
             "lib/cuke_sniffer/report/title.html.erb",
             "lib/cuke_sniffer/report/features.html.erb",
             "lib/cuke_sniffer/report/hooks.html.erb",
             "lib/cuke_sniffer/report/improvement_list.html.erb",
             "lib/cuke_sniffer/report/min_template.html.erb",
             "lib/cuke_sniffer/report/standard_template.html.erb",
             "lib/cuke_sniffer/report/rules.html.erb",
             "lib/cuke_sniffer/report/step_definitions.html.erb",
             "lib/cuke_sniffer/report/summary.html.erb",
             "lib/cuke_sniffer/report/legend.html.erb",
             "lib/cuke_sniffer.rb",
             "lib/cuke_sniffer/constants.rb",
             "lib/cuke_sniffer/feature.rb",
             "lib/cuke_sniffer/feature_rules_evaluator.rb",
             "lib/cuke_sniffer/rule_target.rb",
             "lib/cuke_sniffer/rule_config.rb",
             "lib/cuke_sniffer/scenario.rb",
             "lib/cuke_sniffer/step_definition.rb",
             "lib/cuke_sniffer/rule.rb",
             "lib/cuke_sniffer/formatter.rb",
             "lib/cuke_sniffer/summary_node.rb",
             "lib/cuke_sniffer/rules_evaluator.rb",
             'lib/cuke_sniffer/cuke_sniffer_helper.rb',
             'lib/cuke_sniffer/summary_helper.rb',
             'lib/cuke_sniffer/dead_steps_helper.rb',
             "lib/cuke_sniffer/cli.rb",
             "lib/cuke_sniffer/hook.rb",
             "bin/cuke_sniffer"
  ]
  s.license = 'MIT'
  s.homepage = 'https://github.com/r-cochran/cuke_sniffer'
  s.add_runtime_dependency 'roxml'
  s.executables = ["cuke_sniffer"]
end
