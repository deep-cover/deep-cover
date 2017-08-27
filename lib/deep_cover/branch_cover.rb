require 'pry'
module DeepCover
  class BranchCover < Parser::Rewriter
    def on_node(node)
      @done ||= 0
      @done += 1
      return if @done > 2
      @source_rewriter.transaction do
        @source_rewriter.insert_after node.loc.expression, ')'
        @source_rewriter.insert_before node.loc.expression, '('
      end
    end

    def process(node)
      super
      on_node(node)
      node
    end
  end
end
