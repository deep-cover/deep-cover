module DeepCover
  module HasChild
    def self.included(base)
      base.extend ClassMethods
    end

    CHILDREN = {}
    CHILDREN_TYPES = {}

    def initialize(*)
      super
      self.validate_children_types(children)
    end

    def call_handler name, child
      child_name = self.class.child_index_to_name(child.index, children.size) rescue binding.pry
      method_name = name % {name: child_name}
      if respond_to?(method_name)
        args = [child] unless method(method_name).arity == 0
        answer = send(method_name, *args)
      end
      answer || yield
    end

    def validate_children_types(nodes)
      mismatches = self.class.check_children_types(nodes)
      unless mismatches.empty?
        raise TypeError, "Invalid types for #{self.class}(type: #{self.type}): #{mismatches}"
      end
    end

    module ClassMethods
      def has_child(flow_entry_count: nil, rewrite: nil, rest: false, **h)
        name, type = h.first
        update_children_const(name, rest: rest)
        define_accessor(name)
        add_runtime_check(name, type)
        define_handler(:"#{name}_flow_entry_count", flow_entry_count)
        define_handler(:"rewrite_#{name}", rewrite)
        self
      end

      def has_extra_children(**h)
        has_child(rest: true, **h)
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
      private

      def expected_types(nodes)
        types = self::CHILDREN.flat_map do |name, i|
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
          expected.any? {|exp| node_matches_type?(node, exp) }
        when Class
          node.is_a?(expected)
        when Symbol
          node.is_a?(Node) && node.type == expected
        else
          raise "Unrecognized expected type #{expected}"
        end
      end

      def inherited(subclass)
        subclass.const_set :CHILDREN, {}
        subclass.const_set :CHILDREN_TYPES, {}
        super
      end

      def const_missing(name)
        const_set(name, self::CHILDREN.fetch(name.downcase) { return super })
      end

      def update_children_const(name, rest: false)
        children_map = self::CHILDREN
        already_has_rest = false
        children_map.each do |key, value|
          if value.is_a? Range
            children_map[key] = children_map[key].begin..(children_map[key].end - 1)
            already_has_rest = true
          elsif value < 0
            children_map[key] -= 1
          end
        end
        children_map[name] = if rest
          raise "Can't have two rest childrens" if already_has_rest
          children_map.size..-1
        elsif already_has_rest
          -1
        else
          children_map.size
        end
      end

      def define_accessor(name)
        class_eval <<-end_eval, __FILE__, __LINE__
          def #{name}
            children[#{name.upcase}]
          end
        end_eval
      end

      def define_handler(name, method)
        case method
        when nil
          # Nothing to do
        when Symbol
          alias_method name, method
        when Proc
          define_method(name, &method)
        else
          define_method(name) {|*| method }
        end
      end

      def add_runtime_check(name, type)
        self::CHILDREN_TYPES[name] = type
      end
    end
  end
end
