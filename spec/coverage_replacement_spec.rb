# frozen_string_literal: true

require 'spec_helper'
require 'coverage'
require 'deep_cover/core_ext/coverage_replacement'
# These are autoloaded, but will influence the builtin coverage, so preload them
require 'rspec/matchers/built_in/operators.rb'
require 'rspec/matchers/built_in/contain_exactly.rb'

module DeepCover
  [::Coverage, CoverageReplacement].each do |cov_module|
    describe cov_module do
      after do
        DeepCover.reset
        ::Coverage.result rescue nil
      end

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

      if RUBY_VERSION >= '2.5' || cov_module.respond_to?(:running?)
        it "returns it's current state" do
          cov_module.running?.should == false
          cov_module.start
          cov_module.running?.should == true
          cov_module.result
          cov_module.running?.should == false
        end
      end
    end
  end
end
