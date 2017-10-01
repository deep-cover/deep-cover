
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

      if @options[:not_higher_than_builtin]
        line_hits = line_hits.zip(@covered_code.builtin_executable_lines).map do |hits, builtin_executable|
          if !builtin_executable && hits && hits > 0
            # Avoid getting higher coverage than builtin because we can detect more
            # things as being executed or not than builtin
            nil
          else
            hits
          end
        end
      end
      line_hits
    end

    def apply_line_hits(node, line_hits)
      node.executed_locs.each do |loc|
        lineno = loc.line - 1
        line_hits[lineno] = [line_hits[lineno] || 0, node.flow_entry_count].max
      end
      node.children_nodes.each{|c| apply_line_hits(c, line_hits) }
    end
  end
end
