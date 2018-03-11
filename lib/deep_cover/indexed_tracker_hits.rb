# frozen_string_literal: true

module DeepCover
  bootstrap

  class IndexedTrackerHits
    extend Forwardable
    def_delegators :@index, :each, :each_key, :map, :transform_values, :to_h, :to_hash

    def initialize(index = {})
      @index = index
    end

    def [](val)
      @index[val] ||= []
    end

    def merge!(index_tracker_hits)
      @index.merge!(index_tracker_hits) { |_h, actual, to_merge| actual.merge!(to_merge) }
      self
    end
  end
end
