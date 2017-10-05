
module DeepCover
  class LineCoverageInterpreter
    def initialize(covered_code, **options)
      @covered_code = covered_code
      @options = options
    end

    def generate_results
      line_hits = Array.new(@covered_code.nb_lines)
      @covered_code.covered_ast.each_node do |node|
        if node.executable?
          node.executed_locs.each do |loc|
            lineno = loc.line - 1
            line_hits[lineno] = [line_hits[lineno] || 0, node.execution_count].max
          end
        end
      end

      line_hits
    end
  end
end
