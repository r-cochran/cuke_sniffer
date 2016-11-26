source 'http://rubygems.org'

group :development do
  gem 'rake'
  gem 'rspec', '< 3.0' # Will have to update test assertions before using a recent version of rspec
  gem 'cucumber'
  gem 'nokogiri', '~> 1.0', '>=1.6.2'
  gem 'roxml'
  gem 'jasmine'
  gem 'phantomjs', '~> 1.9.8.0'
end

if RUBY_VERSION =~ /^1\./
  gem 'json', '< 2.0' # The 'json' gem drops pre-Ruby 2.x support on/after this version
end

if (RUBY_VERSION =~ /^2\.[01]\./ || RUBY_VERSION !~ /^2\.2\.[01]/)
  gem 'rack', '< 2.0' # The 'rack' gem requires >= Ruby 2.2.2 on/after this version
  gem 'activesupport', '< 5.0' # The 'activesupport' gem requires >= Ruby 2.2.2 on/after this version
end

gemspec
