# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

RSpec::Core::RakeTask.new(:spec).tap { |task| task.pattern = 'spec/*_spec.rb, spec/*/*_spec.rb' }

desc 'Run all tests'
RSpec::Core::RakeTask.new('spec:all') do |task|
  task.pattern = 'spec/*_spec.rb, spec/*/*_spec.rb'
  task.rspec_opts = '-O .rspec_all'
end

multitask default: RUBY_VERSION > '2.1' ? [:rubocop, :spec] : :spec
multitask 'test:all' => RUBY_VERSION > '2.1' ? [:rubocop, 'spec:all'] : 'spec:all'

namespace :dev do
  desc 'Setup extra things required to run the spec suite'
  task :install do
    commands = []

    if RUBY_VERSION >= '2.2.2' && (!defined?(RUBY_ENGINE) || RUBY_ENGINE != 'jruby')
      commands << 'bundle install --gemfile=spec/full_usage/rails51_project/Gemfile'
    end
    commands << 'bundle install --gemfile=spec/cli_fixtures/simple_rails42_app/Gemfile'
    commands << 'bundle install --gemfile=spec/cli_fixtures/rails_like_gem/Gemfile'

    commands.each do |command|
      puts "Running: #{command}"
      Bundler.with_clean_env do
        unless system(command)
          puts "Failed to run `#{command}`, see above for details. When it is fixed, try running this rake task again."
          exit(1)
        end
      end
      puts "Command succeeded: #{command}"
    end
  end
end
