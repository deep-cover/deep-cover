module DeepCover
  module Node::Mixin
    module HasLocal
      def self.included(base)
        base.extend ClassMethods
      end

      def initialize(*)
        @local_offset = covered_code.allocate_local if self.class.needs_local
        super
      end

      def local_source
        covered_code.local_source(@local_offset) if @local_offset
      end

      module ClassMethods
        attr_accessor :needs_local

        def has_local
          self.needs_local = true
        end
      end
    end
  end
end
