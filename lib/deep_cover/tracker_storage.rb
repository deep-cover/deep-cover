# frozen_string_literal: true

module DeepCover
  bootstrap

  # List of allocated trackers from a bucket.
  # Should be thought of as a simple array of integers with
  # a limited interface.
  class TrackerBucket
    class TrackerStorage
      extend Forwardable
      def_delegators :@array, :[], :size, :each, :map, :fetch

      attr_reader :bucket

      def initialize(bucket, index: nil, size: 0)
        @bucket = bucket
        @array, @index = @bucket.send(:allocate_tracker_storage, index)
        allocate_trackers(size - @array.size)
      end

      # Returns a range of tracker ids
      def allocate_trackers(nb_needed)
        prev = size
        @array.concat(Array.new(nb_needed, 0)) if nb_needed > 0 # Allow nb_needed <= 0
        prev...size
      end

      def setup_source
        "(#{bucket.setup_source})[#{@index}]||=Array.new(#{size},0)"
      end

      def tracker_source(tracker_id)
        "#{bucket.source}[#{@index}][#{tracker_id}]+=1"
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
end
