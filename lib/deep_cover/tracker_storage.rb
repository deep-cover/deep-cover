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

      def initialize(bucket, index: nil)
        @bucket = bucket
        @allocated = 0
        @array, @index = @bucket.send(:allocate_tracker_storage, index)
      end

      # Returns a range of tracker ids
      def allocate_trackers(nb_needed)
        prev = @allocated
        @allocated += nb_needed
        missing = @allocated - @array.size
        @array.concat(Array.new(missing, 0)) if missing > 0
        prev...@allocated
      end

      def setup_source
        "(#{bucket.setup_source})[#{@index}]||=Array.new(#{size},0)"
      end

      def tracker_source(tracker_id)
        "#{bucket.source}[#{@index}][#{tracker_id}]+=1"
      end

      def tracker_hits
        @array.dup.freeze
      end

      def tracker_hits=(new_hits)
        if new_hits.size != @array.size
          warn 'Replacing tracker hits with array of different size'
        end
        @array.replace(new_hits)
      end

      private

      def marshal_dump
        {bucket: @bucket, index: @index, size: @array.size}
      end

      def marshal_load(bucket:, index:, size:)
        initialize(bucket, index: index)
        allocate_trackers(size - @array.size)
      end
    end
  end
end
