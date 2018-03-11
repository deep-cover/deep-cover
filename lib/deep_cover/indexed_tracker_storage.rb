# frozen_string_literal: true

module DeepCover
  bootstrap

  class IndexedTrackerStorage
    extend Forwardable
    def_delegators :@index, :each, :each_key, :map, :transform_values

    attr_reader :bucket

    def initialize(bucket)
      @bucket = bucket
      @index = {}
    end

    def [](val)
      @index[val] ||= TrackerBucket::TrackerStorage.new(@bucket)
    end

    def indexed_tracker_hits
      IndexedTrackerHits.new(@index.transform_values(&:tracker_hits))
    end

    def indexed_tracker_hits=(ith)
      ith.each do |path, tracker_hits|
        self[path].tracker_hits = tracker_hits
      end
    end
  end
end
