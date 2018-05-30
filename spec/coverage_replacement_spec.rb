# frozen_string_literal: true

require 'spec_helper'
require 'deep_cover/core_ext/coverage_replacement'
require 'coverage'
# These are autoloaded, but will influence the builtin coverage, so preload them
require 'rspec/matchers/built_in/operators.rb'
require 'rspec/matchers/built_in/contain_exactly.rb'

module DeepCover
  [::Coverage, CoverageReplacement].each do |cov_module|
    describe cov_module do
      if cov_module == CoverageReplacement
        before do
          DeepCover.configure do
            paths(paths + ['./spec/samples'])
          end
        end
      end

      after do
        DeepCover.reset
        ::Coverage.result rescue nil
        $LOADED_FEATURES.delete(sample_require_path)
      end

      let(:sample_require_path) { File.realpath('samples/basic_branching.rb', __dir__) }

      it 'can be started as many times as desired' do
        cov_module.start.should == nil
        cov_module.start.should == nil
      end

      it 'allows calling result at most once after each start' do
        expect { cov_module.result }.to raise_error(RuntimeError)
        cov_module.start
        cov_module.result.should == {}
        expect { cov_module.result }.to raise_error(RuntimeError)
        cov_module.start.should == nil
        cov_module.result.should == {}
      end

      if RUBY_VERSION >= '2.3' || cov_module.respond_to?(:peek_result)
        it 'allows calling peek_result many times, once after a start' do
          expect { cov_module.peek_result }.to raise_error(RuntimeError)
          cov_module.start
          cov_module.peek_result.should == {}
          cov_module.peek_result.should == {}
          cov_module.result.should == {}
          expect { cov_module.peek_result }.to raise_error(RuntimeError)
          cov_module.start
          cov_module.peek_result.should == {}
          cov_module.peek_result.should == {}
        end
      end

      if RUBY_VERSION >= '2.5' || cov_module.respond_to?(:running?)
        it "returns it's current state" do
          cov_module.running?.should == false
          cov_module.start
          cov_module.running?.should == true
          cov_module.result
          cov_module.running?.should == false
        end
      end

      if RUBY_VERSION >= '2.5' || cov_module == CoverageReplacement
        it 'accepts a hash of coverage targets' do
          cov_module.running?.should == false
          cov_module.start(branches: true)
          cov_module.running?.should == true
        end

        it 'can start with the same coverage targets multiple times' do
          cov_module.start(branches: true).should == nil
          cov_module.start(branches: true).should == nil
        end

        it 'raises an exception if started multiple times with different targets' do
          cov_module.start(branches: true)
          expect do
            cov_module.start(methods: true)
          end.to raise_error(RuntimeError)

          expect do
            cov_module.start
          end.to raise_error(RuntimeError)
        end

        it 'raises an exception if started with no targets' do
          expect do
            cov_module.start({})
          end.to raise_error(RuntimeError)

          expect do
            cov_module.start(no_a_valid_one: true)
          end.to raise_error(RuntimeError)
        end


        def ensure_coverage_data(cov_module, coverages_and_have_content)
          peeked = cov_module.peek_result
          result = cov_module.result
          peeked.should == result

          result.should be_a Hash
          file_result = result[sample_require_path]
          file_result.should be_a Hash

          coverages_and_have_content.each do |coverage_name, has_content|
            file_result[coverage_name].should_not == nil
            file_result[coverage_name].empty?.should == !has_content
          end

          (file_result.keys - coverages_and_have_content.keys).should be_empty
        end

        it 'result has branches coverage if started with branches: true' do
          cov_module.start(branches: true)
          require sample_require_path
          ensure_coverage_data(cov_module, branches: true)
        end

        it 'result has lines coverage if started with lines: true' do
          cov_module.start(lines: true)
          require sample_require_path
          ensure_coverage_data(cov_module, lines: true)
        end

        it 'result has empty methods coverage if started with methods: true' do
          cov_module.start(methods: true)
          require sample_require_path
          ensure_coverage_data(cov_module, methods: false)
        end

        it 'result has every coverage if started with full hash' do
          cov_module.start(branches: true, lines: true, methods: true)
          require sample_require_path
          ensure_coverage_data(cov_module, branches: true, lines: true, methods: false)
        end

        it 'result has every coverage if started with :all' do
          cov_module.start(:all)
          require sample_require_path
          ensure_coverage_data(cov_module, branches: true, lines: true, methods: false)
        end

        it 'result has every coverage if started with no arg' do
          cov_module.start
          require sample_require_path

          peeked = cov_module.peek_result
          result = cov_module.result
          peeked.should == result

          result.should be_a Hash
          file_result = result[sample_require_path]
          file_result.should be_a Array

          file_result.should_not be_empty
        end
      end
    end
  end
end
