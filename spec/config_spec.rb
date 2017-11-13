# frozen_string_literal: true
require "spec_helper"

module DeepCover
  RSpec.describe Config do
    let(:config) { Config.new({ignore_uncovered: []}) }
    describe :ignore_uncovered do

      def result
        config.to_h[:ignore_uncovered]
      end

      it "be modified by {ignore|detect}_uncovered}" do
        config.ignore_uncovered :raise
        result.should == [:raise]
        config.ignore_uncovered :trivial_if, :case_implicit_else
        result.should =~ [:raise, :trivial_if, :case_implicit_else]
        config.detect_uncovered :raise, :trivial_if, :default_argument
        result.should =~ [:case_implicit_else]
      end

      it "rejects unknown options" do
        -> { config.ignore_uncovered :foo }.should raise_error(ArgumentError)
        -> { config.detect_uncovered :foo }.should raise_error(ArgumentError)
      end
    end
  end
end
