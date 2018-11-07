# frozen_string_literal: true

require_relative 'spec_helper'

module DeepCover
  RSpec.describe 'CLI', :slow do
    def run_command(command, expected_errors = /^$/)
      require 'open3'
      out, errors, _status = Bundler.with_clean_env do
        Open3.capture3(command)
      end
      errors.should match expected_errors unless RUBY_PLATFORM == 'java'
      out
    end

    let(:expected_errors) { /^$/ }
    let(:output) do
      run_command(command, expected_errors)
    end

    describe 'deep-cover exec' do
      let(:options) { '' }
      let(:command) { "exe/deep-cover exec -C=spec/code_fixtures/#{path} -o=false #{options} rake" }
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
        let(:command) { %{exe/deep-cover exec -o=false ruby -Ilib -Icore_gem/lib -e 'require "deep-cover"; puts :hello'} }
        it do
          skip('New thor version is needed')
          should include 'hello'
          should =~ /No HTML generated/
        end
      end

      describe 'for a multiple component gem like rails' do
        let(:expected_errors) { /Errors in another_component_gem/ }
        let(:options) { '--reporter=istanbul' }
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
    end

    describe 'deep-cover gather' do
      let(:options) { '' }
      let(:command) { "exe/deep-cover gather -C=spec/code_fixtures/#{path} #{options} rake" }
      subject { output }
      describe 'for a simple gem' do
        let(:path) { 'covered_trivial_gem' }

        it 'keeps old trackers' do
          fake_tracker_path = "spec/code_fixtures/#{path}/deep_cover/trackers123.dct"
          File.write(fake_tracker_path, 'bad data!')
          output

          File.exist?(fake_tracker_path).should == true
        end

        it 'add a trackers file' do
          pre_tracker_files = Dir["spec/code_fixtures/#{path}/deep_cover/*.dct"]
          output
          post_tracker_files = Dir["spec/code_fixtures/#{path}/deep_cover/*.dct"]

          post_tracker_files.size.should == pre_tracker_files.size + 1
        end
      end
    end

    describe 'deep-cover merge' do
      let(:options) { '' }
      let(:command) { "exe/deep-cover merge -C=spec/code_fixtures/#{path} #{options}" }
      subject { output }

      before(:each) do
        # clear trackers
        Dir["spec/code_fixtures/#{path}/deep_cover/*.dct"].each { |path| File.delete(path) }
      end

      describe 'for a simple gem' do
        let(:path) { 'covered_trivial_gem' }

        it 'does nothing if there are no trackers to merge' do
          output
          post_tracker_files = Dir["spec/code_fixtures/#{path}/deep_cover/*.dct"]
          post_tracker_files.size.should == 0
        end

        it 'it merges every tracker files into one' do
          trackers1_path = "spec/code_fixtures/#{path}/deep_cover/trackers123.dct"
          File.write(trackers1_path, JSON.dump(version: DeepCover::VERSION,
                                               tracker_hits_per_path: {'hello1' => [1, 2, 3],
                                                                       'hello2' => [4, 5, 6],
                                                                         }))

          trackers2_path = "spec/code_fixtures/#{path}/deep_cover/trackers456.dct"
          File.write(trackers2_path, JSON.dump(version: DeepCover::VERSION,
                                               tracker_hits_per_path: {'hello1' => [2, 2, 2],
                                                                       'hello3' => [7, 8, 9],
                                                                         }))

          output

          File.exist?(trackers1_path).should == false
          File.exist?(trackers2_path).should == false
          Dir["spec/code_fixtures/#{path}/deep_cover/*.dct"].size.should == 1
          result = JSON.parse(File.read(Dir["spec/code_fixtures/#{path}/deep_cover/*.dct"].first)).transform_keys(&:to_sym)
          result.should == {version: DeepCover::VERSION,
                            tracker_hits_per_path: {'hello1' => [3, 4, 5],
                                                    'hello2' => [4, 5, 6],
                                                    'hello3' => [7, 8, 9],
                                                   },
                           }
        end
      end
    end

    describe 'deep-cover report' do
      let(:options) { '--reporter=istanbul' }
      let(:command) { "exe/deep-cover report -C=spec/code_fixtures/#{path} -o=false #{options}" }
      subject { output }

      describe 'for a simple gem' do
        let(:path) { 'covered_trivial_gem' }
        it do
          # Run deep-cover exec to setup initial data
          exec_output = run_command("exe/deep-cover exec -C=spec/code_fixtures/#{path} -o=false #{options} rake")
          exec_table = exec_output[/^---(.|\n)*\z/]

          output.should == exec_table
        end
      end
    end

    describe 'deep-cover clear' do
      let(:options) { '' }
      let(:command) { "exe/deep-cover clear -C=spec/code_fixtures/#{path} #{options}" }
      subject { output }

      before(:each) do
        cache_directory = "spec/code_fixtures/#{path}/deep_cover"
        Dir.mkdir(cache_directory) unless File.exist?(cache_directory)
        Dir["#{cache_directory}/*"].each { |path| File.delete(path) }
      end

      describe 'for a simple gem' do
        let(:path) { 'covered_trivial_gem' }

        it 'removes trackers if directory becomes empty' do
          tracker_path = "spec/code_fixtures/#{path}/deep_cover/trackers123.dct"
          File.write(tracker_path, 'trackers')

          output

          File.exist?(tracker_path).should == false
          File.exist?(File.dirname(tracker_path)).should == false
        end

        it 'removes trackers but keep directory and other content' do
          tracker_path = "spec/code_fixtures/#{path}/deep_cover/trackers123.dct"
          File.write(tracker_path, 'trackers')
          other_path = "spec/code_fixtures/#{path}/deep_cover/something.else"
          File.write(other_path, 'else')

          output

          File.exist?(tracker_path).should == false
          File.exist?(other_path).should == true
        end
      end
    end

    describe 'The output of deep-cover clone' do
      let(:options) { '' }
      let(:extra_args) { '' }
      let(:command) { "exe/deep-cover clone -o=false --reporter=istanbul -C=spec/code_fixtures/#{path} #{options}" }
      subject { output }

      describe 'for a simple project (not a gem)' do
        let(:path) { '../../core_gem/spec/code_fixtures/simple' }
        let(:command) { "exe/deep-cover clone -o=false --reporter=istanbul -C=spec/code_fixtures/#{path} ruby simple.rb no_deep_cover" }
        it do
          should include 'simple.rb'
          should =~ Regexp.new(%w[beside_simple.rb 100 100 100 100].join('[ |]*'))
        end
      end

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

    ['exe/deep-cover --version', 'exe/deep-cover', 'exe/deep-cover help'].each do |command|
      it "Can run `#{command}`" do
        command.should run_successfully
      end
    end
  end
end
