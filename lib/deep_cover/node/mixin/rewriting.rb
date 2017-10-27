module DeepCover
  module Node::Mixin
    module Rewriting
      def self.included(base)
        base.has_child_handler('rewrite_%{name}')
      end

      # Code to add before and after the node for covering purposes
      def rewrite
      end

      # Default child rewriting rule
      def rewrite_child(child, name=nil)
      end

      # Replaces all the '%{local}' or '%{some_tracker}' in rewriting rules
      def resolve_rewrite(rule, context)
        return if rule == nil
        sources = context.tracker_sources
        rule % {local: covered_code.local_var, node: '%{node}', **sources}
      end

      # Returns an array of [range, rule], where rule is a string containing '%{node}'
      def rewriting_rules
        [
          resolve_rewrite(parent.rewrite_child(self), parent),
          resolve_rewrite(rewrite, self),
        ].compact.map{|rule| [expression, rule]}
      end
    end
  end
end
