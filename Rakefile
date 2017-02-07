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
  version = "1.1.0"
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

task :rebuild_complex_examples do
  rebuildExamples "examples/complex_project/"
end

task :rebuild_simple_examples do
  rebuildExamples "examples/simple_project/"
end

task :rebuild_empty_examples do
  rebuildExamples "examples/empty_project/"
end

task :rebuild_all_examples => [:rebuild_complex_examples, :rebuild_simple_examples, :rebuild_empty_examples]

def rebuildExamples(folder_name)
  target_folder = folder_name + "features"
  system "cuke_sniffer -p " + target_folder + " > " + folder_name + "console_output.txt"
  system "cuke_sniffer -o html " + folder_name + "/cuke_sniffer_results.html -p " + target_folder
  system "cuke_sniffer -o min_html " + folder_name + "/min_cuke_sniffer_results.html -p " + target_folder
  system "cuke_sniffer -o xml " + folder_name + "/cuke_sniffer_results.xml -p " + target_folder
  system "cuke_sniffer -o junit_xml " + folder_name + "/junit_cuke_sniffer_results.xml -p " + target_folder
end
