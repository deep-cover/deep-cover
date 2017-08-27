require 'pry'
module DeepCover
  class BranchCover < Parser::Rewriter
    attr_accessor :covered_code, :original_code, :to_cover

    def initialize
      @to_cover = {}
      super
    end

    def coverage
      $cover = Array.new(@to_cover.keys.max)
      @to_cover.each{|line, _| $cover[line - 1] = 0}
      eval(covered_code)
      $cover
    end

    def on_node(node)
      cur_line = node.loc.expression.line
      @to_cover[cur_line] = true

      @source_rewriter.insert_before_multi node.loc.expression, "($cover[#{cur_line-1}]+=1;"
      @source_rewriter.insert_after_multi node.loc.expression, ')'
    end

    def process(node)
      super
      on_node(node)
      node
    end
  end
end
