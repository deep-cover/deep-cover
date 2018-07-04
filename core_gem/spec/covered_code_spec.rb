# frozen_string_literal: true

require_relative 'spec_helper'

module DeepCover
  describe CoveredCode do
    it 'can be created from an empty source' do
      expect { DeepCover::CoveredCode.new(source: '') }.not_to raise_error
    end

    it 'has a short inspect' do
      DeepCover::CoveredCode.new(source: '', path: 'a path').inspect.should == '#<DeepCover::CoveredCode "a path">'
    end
  end
end
