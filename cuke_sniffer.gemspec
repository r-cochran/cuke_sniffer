Gem::Specification.new do |s|
  s.name = 'cuke_sniffer'
  s.version = '0.0.0'
  s.date = '2013-01-05'
  s.summary = "Hola!"
  s.description = "A ruby library used to root out smells in your cukes."
  s.authors = ["Robert Cochran", "Chris Vaughn", "Robert Anderson", "Mitchell Presar"]
  s.files = ["lib/constants.rb",
             "lib/cuke_sniffer.rb",
             "lib/feature.rb",
             "lib/feature_rules_evaluator.rb",
             "lib/rules_evaluator.rb",
             "lib/rule_config.rb",
             "lib/scenario.rb",
             "lib/step_definition.rb",
             "bin/cuke_sniffer.rb"]
  s.homepage = 'https://github.com/r-cochran/cuke_sniffer'
  s.executables = ["cuke_sniffer.rb"]
end