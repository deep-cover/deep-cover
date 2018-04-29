# frozen_string_literal: true

module DeepCover
  module Node::Mixin
    module ChildCanBeEmpty
      class << self
        attr_accessor :last_empty_position # Ugly hack to pass info from Handler to constructor
        def included(base)
          base.has_child_handler('%{name}_can_be_empty')
        end
      end

      def remap_child(child, name)
        if child == nil
          if (ChildCanBeEmpty.last_empty_position = child_can_be_empty(child, name))
            return Node::EmptyBody
          end
        end
        super
      end

      def child_can_be_empty(_child, _name = nil)
        false
      end
    end
  end
end
