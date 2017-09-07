require 'pry'
module DeepCover
  class Rewriter < ::Parser::Rewriter
    def process(node)
      node.children_nodes.each{|node| process(node)}
      if prefix = node.prefix
        @source_rewriter.insert_before_multi node.loc.expression, prefix
      end
      if suffix = node.suffix
        @source_rewriter.insert_after_multi node.loc.expression, suffix
      end
    end
  end
end
