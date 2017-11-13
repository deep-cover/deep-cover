# frozen_string_literal: true

module DeepCover
  module Node::Mixin
    module HasChild
      def self.included(base)
        base.extend ClassMethods
      end
      CHILDREN = {}.freeze
      CHILDREN_TYPES = {}.freeze

      def initialize(*)
        super
        self.validate_children_types(children)
      end

      def validate_children_types(nodes)
        mismatches = self.class.check_children_types(nodes)
        unless mismatches.empty?
          raise TypeError, "Invalid children types for #{self.class}(type: #{self.type}): #{mismatches}"
        end
      end

      module ClassMethods
        def has_child(rest_: false, refine_: false, **h)
          raise "Needs exactly one custom named argument, got #{h.size}" if h.size != 1
          name, types = h.first
          raise TypeError, "Expect a Symbol for name, got a #{name.class} (#{name.inspect})" unless name.is_a?(Symbol)
          update_children_const(name, rest: rest_) unless refine_
          define_accessor(name) unless refine_
          add_runtime_check(name, types)
          self
        end

        def has_extra_children(**h)
          has_child(**h, rest_: true)
        end

        def refine_child(child_name = nil, **h)
          if child_name
            h = {child_name => self::CHILDREN_TYPES.fetch(child_name), **h}
          end
          has_child(**h, refine_: true)
        end

        def child_index_to_name(index, nb_children)
          self::CHILDREN.each do |name, i|
            return name if i == index || (i == index - nb_children) ||
                           (i.is_a?(Range) && i.begin <= index && i.end + nb_children >= index)
          end
          raise IndexError, "index #{index} does not correspond to any child of #{self}"
        end

        def check_children_types(nodes)
          types = expected_types(nodes)
          nodes_mismatches(nodes, types)
        end

        def min_children
          self::CHILDREN.values.grep(Integer).size
        end

        private

        def expected_types(nodes)
          self::CHILDREN.flat_map do |name, i|
            type = self::CHILDREN_TYPES[name]
            Array.new(nodes.values_at(i).size, type)
          end
        end

        def nodes_mismatches(nodes, types)
          nodes = nodes.dup
          nodes[nodes.size...types.size] = nil
          nodes.zip(types).reject do |node, type|
            node_matches_type?(node, type)
          end
        end

        def node_matches_type?(node, expected)
          case expected
          when :any
            true
          when nil
            node.nil?
          when Array
            expected.any? { |exp| node_matches_type?(node, exp) }
          when Class
            node.is_a?(expected)
          when Symbol
            node.is_a?(Node) && node.type == expected
          else
            raise "Unrecognized expected type #{expected}"
          end
        end

        def inherited(subclass)
          subclass.const_set :CHILDREN, self::CHILDREN.dup
          subclass.const_set :CHILDREN_TYPES, self::CHILDREN_TYPES.dup
          super
        end

        def update_children_const(name, rest: false)
          children_map = self::CHILDREN
          already_has_rest = false
          children_map.each do |key, value|
            if value.is_a? Range
              children_map[key] = children_map[key].begin..(children_map[key].end - 1)
              already_has_rest = key
            elsif value < 0
              children_map[key] -= 1
            end
          end
          children_map[name] = if rest
                                 if already_has_rest
                                   raise "Class #{self} can't have extra children '#{name}' because it already has '#{name}' (#{children_map})"
                                 end
                                 children_map.size..-1
                               elsif already_has_rest
                                 -1
                               else
                                 children_map.size
                               end
        end

        def define_accessor(name)
          warn "child name '#{name}' conflicts with existing method for #{self}" if method_defined? name
          class_eval <<-EVAL, __FILE__, __LINE__ + 1
            def #{name}
              children[CHILDREN.fetch(#{name.inspect})]
            end
          EVAL
        end

        def add_runtime_check(name, type)
          self::CHILDREN_TYPES[name] = type
        end
      end
    end
  end
end
