module DeepCover
  module Node::Mixin
    RESET_LOCAL_VAR = {local_var_level: 0, local_var_id: 0}

    module HasLocal
      def self.included(base)
        base.has_child_handler '%{name}_local_var_level'
        base.has_child_handler '%{name}_local_var_id'
        base.extend ClassMethods
        base.include HasLocalDefault
      end

      def local_var_id
        parent.child_local_var_id(self)
      end

      def local_var_level
        parent.child_local_var_level(self)
      end

      def local_source
        covered_code.local_var_source(level: local_var_level, id: local_var_id) if self.class.needs_local
      end

      module HasLocalDefault
        def child_local_var_id(_child)
          super || (local_var_id + (self.class.needs_local ? 1 : 0))
        end

        def child_local_var_level(_child)
          super || local_var_level
        end
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
