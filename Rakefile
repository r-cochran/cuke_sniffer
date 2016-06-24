require 'rubygems'
require 'bundler'
require 'rspec/core/rake_task'
require 'jasmine'

load 'jasmine/tasks/jasmine.rake'

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.ruby_opts = "-I lib:spec"
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = "--color"
end
task :spec


task :lib do
  $LOAD_PATH.unshift(File.expand_path("lib", File.dirname(__FILE__)))
end

task :reload_gem do
  gem_name = "cuke_sniffer"
  version = "1.0.0"
  system "gem uninstall #{gem_name}"
  system "gem build #{gem_name}.gemspec"
  system "gem install #{gem_name}-#{version}.gem"
end

task :travis do
  ["rspec spec", "rake jasmine:ci"].each do |cmd|
    puts "Starting to run #{cmd}..."
    system("export DISPLAY=:99.0 && bundle exec #{cmd}")
    raise "#{cmd} failed!" unless $?.exitstatus == 0
  end
end

task :default => :spec
