module DeepCover
  class Node::EmptyBody < Node
    def initialize(base_node, parent: raise, index: 0, position: ChildCanBeEmpty.last_empty_position)
      @position = position
      super(base_node, parent: parent, index: index, base_children: [])
    end

    def type
      :EmptyBody
    end

    def loc_hash
      return {} if @position == true
      {expression: @position}
    end

    def is_statement
      false
    end

    # When parent rewrites us, the %{node} must always be at the beginning because our location can
    # also be rewritten by out parent, and we want the rewrite to be after it.
    def rewriting_rules
      rules = super
      rules.map do |expression, rule|
        [expression, "%{node};#{rule.sub('%{node}', 'nil;')}"]
      end
    end
  end
end
