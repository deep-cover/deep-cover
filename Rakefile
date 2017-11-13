# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec).tap { |task| task.pattern = 'spec/*_spec.rb, spec/*/*_spec.rb' }

task default: :spec


namespace :dev do
  desc 'Setup extra things required to run the spec suite'
  task :install do
    commands = []

    if RUBY_VERSION >= '2.2.2' && (!defined?(RUBY_ENGINE) || RUBY_ENGINE != 'jruby')
      commands << 'bundle install --gemfile=spec/full_usage/rails51_project/Gemfile'
    end
    commands << 'bundle install --gemfile=spec/cli_fixtures/simple_rails42_app/Gemfile'

    commands.each do |command|
      puts "Running: #{command}"
      unless system(command)
        puts "Failed to run `#{command}`, see above for details. When it is fixed, try running this rake task again."
        exit(1)
      end
      puts "Command succeeded: #{command}"
    end
  end
end
