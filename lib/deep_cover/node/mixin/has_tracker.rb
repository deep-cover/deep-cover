require 'backports/2.1.0/enumerable/to_h'

module DeepCover
  module Node::Mixin
    module HasTracker
      def self.included(base)
        base.extend ClassMethods
        setup_constants(base)
      end

      def self.setup_constants(base)
        base.const_set :TRACKERS, {}
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
        def inherited(base)
          super
          HasTracker.setup_constants(base)
        end

        def has_tracker(name)
          i = self::TRACKERS[name] = self::TRACKERS.size
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
    end
  end
end
