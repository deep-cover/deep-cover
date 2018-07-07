# frozen_string_literal: true

require_relative 'spec_helper'

module DeepCover
  RSpec.describe FlagCommentAssociator do
    let(:code) do
      <<-RUBY
      1 && :single_line # nocov
      2 && 4.2  # ignore this comment about nocov
         # nocov
      4 && true
         # nocov
      6
         # nocov
      8
      9 && 'include this line' # nocov
      10
      11
      RUBY
    end
    let(:node) { Node[code] }
    let(:covered_code) { node.covered_code }
    let(:associator) { FlagCommentAssociator.new(covered_code) }

    describe :ranges do
      it { associator.ranges.should == [1..1, 4..5, 8..8, 10..11] }
    end

    describe :include? do
      it { associator.include?(node[:sym]).should == true }
      it { associator.include?(node[:float]).should == false }
      it { associator.include?(node[:true]).should == true }
      it { associator.include?(node[:str]).should == false }
    end
  end
end
