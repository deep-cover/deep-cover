require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec).tap{|task| task.pattern = "spec/*_spec.rb, spec/*/*_spec.rb"}

task :default => :spec
