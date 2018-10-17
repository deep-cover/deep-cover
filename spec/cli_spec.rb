# frozen_string_literal: true

require_relative 'spec_helper'

module DeepCover
  RSpec.describe 'CLI', :slow do
    let(:expected_errors) { /^$/ }
    let(:output) do
      require 'open3'
      out, errors, _status = Bundler.with_clean_env do
        Open3.capture3(command)
      end
      errors.should match expected_errors unless RUBY_PLATFORM == 'java'
      out
    end

    describe 'deep-cover exec' do
      let(:options) { '' }
      let(:command) { "cd spec/code_fixtures/#{path} && ../../../exe/deep-cover exec -o=false #{options} rake" }
      subject { output }
      describe 'for a simple gem' do
        let(:path) { 'covered_trivial_gem' }
        it do
          should include '3 examples, 0 failures'
          should =~ /No HTML generated/
        end

        it 'clears old trackers' do
          cache_directory = "spec/code_fixtures/#{path}/deep_cover"
          Dir.mkdir(cache_directory) unless File.exist?(cache_directory)

          fake_tracker_path = "spec/code_fixtures/#{path}/deep_cover/trackers123.dct"
          File.write(fake_tracker_path, 'bad data!')
          output

          File.exist?(fake_tracker_path).should == false
        end
      end

      describe 'for a command with options' do
        let(:command) { %{cd exe; ./deep-cover exec -o=false ruby -I../lib -I../core_gem/lib -e 'require "deep-cover"; puts :hello'} }
        it do
          skip('New thor version is needed')
          should include 'hello'
          should =~ /No HTML generated/
        end
      end
    end

    describe 'The output of deep-cover clone' do
      let(:options) { '' }
      let(:extra_args) { '' }
      let(:command) { "cd exe; ./deep-cover clone -o=false --reporter=istanbul --no-bundle #{options} ../spec/code_fixtures/#{path}" }
      subject { output }
      describe 'for a simple gem' do
        let(:path) { '../../core_gem/spec/code_fixtures/trivial_gem' }
        it do
          should =~ Regexp.new(%w[trivial_gem.rb 80.65 56.25 62.5 91.67].join('[ |]*'))
          should include '3 examples, 0 failures'
        end
      end

      describe 'for a single component gem like activesupport' do
        let(:path) { 'rails_like_gem/component_gem' }
        it do
          should =~ Regexp.new(%w[component_gem.rb 80 100 50].join('[ |]*'))
          should include '1 example, 0 failures'
          should_not include 'another_component'
        end
      end

      describe 'for a multiple component gem like rails' do
        let(:expected_errors) { /Errors in another_component_gem/ }
        let(:path) { 'rails_like_gem' }
        it do
          should =~ Regexp.new(%w[component_gem.rb 80 100 50].join('[ |]*'))
          cov = Process.respond_to?(:fork) ? [100, 50, 100] : [71.43, 50, 50]
          should =~ Regexp.new(['foo.rb', *cov].join('[ |]*'))
          should include '1 example, 0 failures'
          should include 'another_component'
          should include '2 examples, 1 failure'
          should include ' another_component_gem/lib/another_component_gem '
        end
      end

      describe 'for a rails app' do
        let(:path) { 'simple_rails42_app' }
        it do
          should =~ Regexp.new(%w[dummy.rb 100 100 100].join('[ |]*'))
          should =~ Regexp.new(%w[user.rb 85.71 100 50].join('[ |]*'))
          should include '2 runs, 2 assertions, 0 failures, 0 errors, 0 skips'
        end
      end
    end

    it 'Can run `exe/deep-cover --version`' do
      'exe/deep-cover --version'.should run_successfully
    end
  end
end
