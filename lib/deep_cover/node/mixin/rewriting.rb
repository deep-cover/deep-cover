module DeepCover
  module Node::Mixin
    module Rewriting
      def self.included(base)
        base.has_child_handler('rewrite_%{name}')
      end

      # Code to add before and after the node for covering purposes
      def rewrite
        '%{node}'
      end

      def resolve_rewrite(rule, context)
        rule ||= '%{node}'
        sources = context.tracker_sources
        rule.split('%{node}').map{|s| s % {local: local_source, **sources} }
      end

      def rewrite_prefix_suffix
        parent_prefix, parent_suffix = resolve_rewrite(parent.rewrite_child(self), parent)
        prefix, suffix = resolve_rewrite(rewrite, self)
        [
          "#{parent_prefix}#{prefix}",
          "#{suffix}#{parent_suffix}"
        ]
      end
    end
  end
end
