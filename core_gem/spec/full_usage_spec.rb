# frozen_string_literal: true

require_relative 'spec_helper'

FIXTURE_PATH = File.realpath('code_fixtures', __dir__)

RSpec.describe 'DeepCover usage' do
  ['', 'uncovered', 'takeover', 'takeover uncovered', 'no_deep_cover'].each do |args|
    command = "ruby #{JRUBY_DEV_OPTION} simple/simple.rb #{args}"
    it "`#{command}`" do
      command.split.should run_successfully.from_dir(FIXTURE_PATH).and_output('Done')
    end
  end

  describe '', :slow do
    it 'for code that changes the configuration (without .deep_cover.rb)' do
      ['ruby', JRUBY_DEV_OPTION, 'with_configure/test.rb'].compact.should(
          run_successfully.from_dir(FIXTURE_PATH).and_output(
              '{:foo=>[nil, nil, 1, nil, 1, 1, 2, 0, nil, 2, nil, nil], :bar=>nil}'
          )
      )
    end

    it 'for code that changes the configuration (also with .deep_cover.rb)' do
      ['ruby', JRUBY_DEV_OPTION, 'test.rb'].compact.should(
          run_successfully.from_dir("#{FIXTURE_PATH}/with_configure").and_output(
              '{:foo=>[nil, nil, 1, nil, 1, 1, 2, nil, nil, 2, nil, nil], :bar=>nil}'
          )
      )
    end

    xit 'Can still require gems when there is no bundler' do
      'gem install --local spec/code_fixtures/trivial_gem/pkg/trivial_gem-0.1.0.gem'.should run_successfully
      %(ruby #{JRUBY_DEV_OPTION} -e 'require "./lib/deep_cover"; DeepCover.start; require "trivial_gem"').should run_successfully
    end

    it 'Can `rspec` a rails51 app' do
      skip if RUBY_VERSION < '2.2.2'
      skip if RUBY_VERSION >= '2.7'
      skip if RUBY_PLATFORM == 'java'
      'bundle exec rspec'.should run_successfully.from_dir("#{FIXTURE_PATH}/rails51_project")
    end

    it 'Can `rake test` a rails51 app (minitest)' do
      skip if RUBY_VERSION < '2.2.2'
      skip if RUBY_VERSION >= '2.7'
      skip if RUBY_PLATFORM == 'java'
      'bundle exec rake test'.should run_successfully.from_dir("#{FIXTURE_PATH}/rails51_project")
    end

    it 'Does not modify visibility of methods' do
      skip if RUBY_PLATFORM == 'java'
      'ruby simple/visibility_check.rb'.should run_successfully.from_dir(FIXTURE_PATH).and_output('ok')
    end
  end
end
