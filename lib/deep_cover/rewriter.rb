require 'pry'
module DeepCover
  class Rewriter < Parser::Rewriter
   def on_node(node)
      @source_rewriter.insert_before_multi node.loc.expression, "($_cov[#{node.buffer.nb}][#{node.nb}]+=1;"
      @source_rewriter.insert_after_multi node.loc.expression, ')'
    end

    def process(node)
      super
      on_node(node)
      node
    end
  end
end
