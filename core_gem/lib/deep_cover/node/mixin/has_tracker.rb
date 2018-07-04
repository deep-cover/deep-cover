# frozen_string_literal: true

module DeepCover
  module Node::Mixin
    module HasTracker
      def self.included(base)
        base.extend ClassMethods
      end
      TRACKERS = {}

      def initialize(*)
        @tracker_offset = tracker_storage.allocate_trackers(self.class::TRACKERS.size).begin
        super
      end

      def tracker_storage
        covered_code.tracker_storage
      end

      def tracker_sources
        self.class::TRACKERS.map do |name, _|
          [:"#{name}_tracker", send(:"#{name}_tracker_source")]
        end.to_h
      end

      module ClassMethods
        def inherited(base)
          base.const_set :TRACKERS, self::TRACKERS.dup
          super
        end

        def has_tracker(name)
          i = self::TRACKERS[name] = self::TRACKERS.size
          class_eval <<-EVAL, __FILE__, __LINE__ + 1
            def #{name}_tracker_source
              tracker_storage.tracker_source(@tracker_offset + #{i})
            end
            def #{name}_tracker_hits
              tracker_storage[@tracker_offset + #{i}]
            end
          EVAL
        end
      end
    end
  end
end
