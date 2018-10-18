# frozen_string_literal: true

require_relative 'spec_helper'

module DeepCover
  RSpec.describe Persistence do
    let(:config) { Config.new }

    describe '.merge_tracker_hits_per_paths' do
      it 'sums each index' do
        Persistence.merge_tracker_hits_per_paths({'hi' => [1, 2, 3]},
                                                 'hi' => [2, 2, 2]).should == {'hi' => [3, 4, 5]}
      end

      it 'adds up the paths' do
        Persistence.merge_tracker_hits_per_paths({'hi' => [1, 2, 3]},
                                                 'hi2' => [2, 2, 2]).should == {'hi' => [1, 2, 3],
                                                                                'hi2' => [2, 2, 2],
}
      end
    end
  end
end
