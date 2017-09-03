require 'pry'
module DeepCover
  class Rewriter < ::Parser::Rewriter

    def initialize(context)
      @context = context
    end

    def process(node)
      # Skip children that aren't node themselves (e.g. the `method` child of a :def node)
      return node unless node.is_a? ::Parser::AST::Node

      covered_node = @context.create(node, process_all(node.children))
      if prefix = covered_node.prefix
        @source_rewriter.insert_before_multi node.loc.expression, prefix
      end
      if suffix = covered_node.suffix
        @source_rewriter.insert_after_multi node.loc.expression, suffix
      end
      covered_node
    end
  end
end
