# frozen_string_literal: true

module DeepCover
  bootstrap

  # List of allocated trackers from a bucket.
  # Should be thought of as a simple array of integers with
  # a limited interface.
  class TrackerList
    attr_reader :bucket, :list

    def initialize(bucket, index: nil, size: 0)
      @bucket = bucket
      @list, @index = @bucket.send(:allocate_tracker_list, index)
      allocate_trackers(size - list.size)
    end

    # Returns a range of tracker ids
    def allocate_trackers(nb_needed)
      prev = size
      list.concat(Array.new(nb_needed, 0)) if nb_needed > 0 # Allow nb_needed <= 0
      prev...size
    end

    def setup_source
      "(#{bucket.setup_source})[#{@index}]||=Array.new(#{size},0)"
    end

    def tracker_source(tracker_id)
      "#{bucket.source}[#{@index}][#{tracker_id}]+=1"
    end

    def tracker_hits(tracker_id)
      list[tracker_id]
    end

    def size
      list.size
    end

    private

    def marshal_dump
      [@bucket, {index: @index, size: size}]
    end

    def marshal_load(args)
      initialize(*args)
    end
  end
end
