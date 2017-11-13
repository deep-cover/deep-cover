# frozen_string_literal: true

module DeepCover
  module Node::Mixin
    module CanAugmentChildren
      def self.included(base)
        base.has_child_handler('remap_%{name}')
        base.singleton_class.prepend ClassMethods
      end

      # Augment creates a covered node from the child_base_node.
      # Caution: receiver is not fully constructed since it is also being augmented.
      #          don't call `children`
      def augment_children(child_base_nodes)
        missing = self.class.min_children - child_base_nodes.size
        if missing > 0
          child_base_nodes = [*child_base_nodes, *Array.new(missing)]
        end
        child_base_nodes.map.with_index do |child, child_index|
          child_name = self.class.child_index_to_name(child_index, child_base_nodes.size)
          if (klass = remap_child(child, child_name))
            klass.new(child, parent: self, index: child_index)
          else
            child
          end
        end
      end
      private :augment_children

      def remap_child(child, name=nil)
        return unless child.is_a?(Parser::AST::Node)
        class_name = Tools.camelize(child.type)
        Node.const_defined?(class_name) ? Node.const_get(class_name) : Node
      end

      module ClassMethods

        # This handles the following shortcuts:
        #   has_child foo: {type: NodeClass, ...}
        # same as:
        #   has_child foo: [], remap: {type: NodeClass, ...}
        # same as:
        #   has_child foo: [NodeClass, ...], remap: {type: NodeClass, ...}
        #
        def has_child(remap: nil, **h)
          name, types = h.first
          if types.is_a? Hash
            raise "Use either remap or a hash as type but not both" if remap
            remap = types
            h[name] = types = []
          end
          if remap.is_a? Hash
            type_map = remap
            remap = -> (child) do
              klass = type_map[child.type] if child.respond_to? :type
              klass ||= type_map[child.class]
              klass
            end
            types.concat(type_map.values).uniq!
          end
          super(**h, remap: remap)
        end
      end
    end
  end
end
