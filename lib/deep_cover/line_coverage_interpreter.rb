
module DeepCover
  class LineCoverageInterpreter
    def initialize(covered_code, **options)
      @covered_code = covered_code
      @options = options
    end

    def generate_results
      line_hits = Array.new(@covered_code.nb_lines)
      return line_hits unless @covered_code.covered_ast
      apply_line_hits(@covered_code.covered_ast, line_hits)

      line_hits
    end

    # TODO: use each_node in generate_results instead of manually iterating to the children
    def apply_line_hits(node, line_hits)
      if node.executable?
        node.executed_locs.each do |loc|
          lineno = loc.line - 1
          line_hits[lineno] = [line_hits[lineno] || 0, node.execution_count].max
        end
      end
      node.children_nodes.each{|c| apply_line_hits(c, line_hits) }
    end
  end
end
