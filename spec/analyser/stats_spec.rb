# frozen_string_literal: true

require 'spec_helper'

module DeepCover
  RSpec.describe Analyser::Stats do
    let(:values) { {executed: 10, not_executed: 1, not_executable: 5, ignored: 2} }
    let(:stats)  { Analyser::Stats.new(**values) }

    it { stats.should be_frozen }
    it { stats.total.should == 18 }
    it { stats.percent.to_h.values.should == [55.56, 5.56, 27.78, 11.11] }
    it { stats.to_h.should == values }
    it { (stats + stats).to_h.values.should == [20, 2, 10, 4] }
    it { stats.with(not_executed: 4).to_h.values.should == [10, 4, 5, 2] }
    it('is memoized') { stats.to_h.should equal stats.to_h }
  end
end
