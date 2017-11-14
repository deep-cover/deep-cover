# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DeepCover usage', :slow do
  it { %w(ruby spec/full_usage/simple/simple.rb).should run_successfully.and_output('Done') }

  it { %w(ruby spec/full_usage/simple/simple.rb takeover).should run_successfully.and_output('Done') }

  it do
    %w(ruby spec/full_usage/with_configure/test.rb).should run_successfully.and_output('[nil, 1, 0, 2, 0, nil, 2, nil, nil]')
  end

  it 'Can still require gems when there is no bundler' do
    'gem install --local spec/cli_fixtures/trivial_gem/pkg/trivial_gem-0.1.0.gem'.should run_successfully
    %(ruby -e 'require "./lib/deep_cover"; DeepCover.start; require "trivial_gem"').should run_successfully
  end

  it 'Can `rspec` a rails51 app' do
    skip if RUBY_VERSION < '2.2.2'
    skip if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
    'rspec'.should run_successfully.from_dir('spec/full_usage/rails51_project')
  end

  it 'Can `rake test` a rails51 app (minitest)' do
    skip if RUBY_VERSION < '2.2.2'
    skip if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
    'rake test'.should run_successfully.from_dir('spec/full_usage/rails51_project')
  end
end
