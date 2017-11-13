# frozen_string_literal: true

module DeepCover
  module Node::Mixin
    module IsStatement
      def self.included(base)
        base.has_child_handler('is_%{name}_statement')
      end

      def is_statement
        parent.is_child_statement(self)
      end

      # Default child rewriting rule
      def is_child_statement(child, name=nil)
        :if_incompatible
      end
    end
  end
end
