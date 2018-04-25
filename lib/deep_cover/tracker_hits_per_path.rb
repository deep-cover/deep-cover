# frozen_string_literal: true

module DeepCover
  bootstrap

  # Should be seen as a hash like {path => tracker_hits, ...},
  # where tracker_hits is simply an array of integers returned from
  # TrackerStorage#tracker_hits.
  # Make it easier to separate some concerns, as well as marshalling.
  #
  class TrackerHitsPerPath
    extend Forwardable
    def_delegators :@index, :each, :each_key, :map, :transform_values, :to_h, :to_hash

    def initialize(index = {})
      @index = index
    end

    def [](val)
      @index[val] ||= []
    end

    def merge!(tracker_hits_per_path)
      @index.merge!(tracker_hits_per_path) { |_h, actual, to_merge| merge_tracker_hits(actual, to_merge) }
      self
    end

    private def merge_tracker_hits(hits, to_merge)
      unless hits.size == to_merge.size
        raise "Attempting to merge trackers of different sizes: #{hits.size} vs #{to_merge.size}"
      end
      hits.map!.with_index { |val, i| val + to_merge[i] }
    end
  end
end
