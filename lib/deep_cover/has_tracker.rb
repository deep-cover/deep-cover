require 'backports/2.1.0/enumerable/to_h'

module DeepCover
  module HasTracker
    def self.included(base)
      base.extend ClassMethods
    end

    def initialize(*)
      @tracker_offset = covered_code.allocate_trackers(self.class::TRACKERS.size).begin
      super
    end

    def tracker_sources
      self.class::TRACKERS.map do |name, _|
        [:"#{name}_tracker", send(:"#{name}_tracker_source")]
      end.to_h
    end

    module ClassMethods
      def has_trackers(*names)
        const_set :TRACKERS, names.each_with_index.to_h
        names.each_with_index do |name, i|
          class_eval <<-end_eval, __FILE__, __LINE__
            def #{name}_tracker_source
              covered_code.tracker_source(@tracker_offset + #{i})
            end
            def #{name}_tracker_hits
              covered_code.tracker_hits(@tracker_offset + #{i})
            end
          end_eval
        end
      end

      def has_tracker(tracker) # Allow singular form
        has_trackers(tracker)
      end
    end
  end
end
