# frozen_string_literal: true
require "spec_helper"

module DeepCover
  describe CoveredCode do
    it "can be created from an empty source" do
      expect { DeepCover::CoveredCode.new(source: '') }.not_to raise_error
    end
  end
end
