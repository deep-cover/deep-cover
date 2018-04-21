# frozen_string_literal: true

module DeepCover
  bootstrap

  # Should be seen as a hash like {path => tracker_storage, ...}
  # Make it easier to separate some concerns, as well as marshalling
  #
  class TrackerStoragePerPath
    extend Forwardable
    def_delegators :@index, :each, :each_key, :map, :transform_values

    attr_reader :bucket

    def initialize(bucket)
      @bucket = bucket
      @index = {}
    end

    def [](path)
      @index[path] ||= @bucket.create_storage
    end

    def tracker_hits_per_path
      TrackerHitsPerPath.new(@index.transform_values(&:tracker_hits))
    end

    def tracker_hits_per_path=(tracker_hits_per_path)
      tracker_hits_per_path.each do |path, tracker_hits|
        self[path].tracker_hits = tracker_hits
      end
    end
  end
end
