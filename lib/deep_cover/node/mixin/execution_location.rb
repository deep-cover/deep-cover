module DeepCover
  module Node::Mixin
    module ExecutionLocation
      def self.included(base)
        base.extend ClassMethods
        base.has_child_handler('%{name}_executed_loc_keys')
      end

      module ClassMethods
        # Macro to define the executed_loc_keys
        def executed_loc_keys(*loc_keys)
          # #flatten allows passing an empty array to be explicit
          loc_keys = loc_keys.flatten
          define_method :executed_loc_keys do
            loc_keys
          end
        end
      end

      def executed_loc_keys
        loc_hash.keys - [:expression]
      end

      def child_executed_loc_keys(_child, _child_name)
        nil
      end

      def executed_locs
        if (keys = parent.child_executed_loc_keys(self))
          inherited = parent.loc_hash.values_at(*keys)
        end
        [  *loc_hash.values_at(*executed_loc_keys),
           *inherited
        ].compact
      end

      def loc_hash
        @loc_hash ||= base_node.respond_to?(:location) ? base_node.location.to_hash : {}
      end

      def expression
        loc_hash[:expression]
      end

      def source
        expression.source if expression
      end

      # Returns an array of character numbers (in the original buffer) that
      # pertain exclusively to this node (and thus not to any children).
      def proper_range
        executed_locs.map(&:to_a).inject([], :+).uniq rescue binding.pry
      end
    end
  end
end
