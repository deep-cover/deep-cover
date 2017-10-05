
module DeepCover
  # This is not actually branch coverage, but we call it like that everything.
  # This is more like atom coverage.
  # To be renamed, along with the rest.
  class BranchCoverageInterpreter
    def initialize(covered_code)
      @covered_code = covered_code
    end

    def generate_results
      buffer = @covered_code.buffer
      bc = buffer.source_lines.map{|line| ' ' * line.size}
      @covered_code.covered_ast.each_node do |node|
        unless node.was_executed?
          bad = node.proper_range
          bad.each do |pos|
            bc[buffer.line_for_position(pos)-1][buffer.column_for_position(pos)] = node.executable? ? 'x' : '-'
          end
        end
      end
      bc.zip(buffer.source_lines){|cov, line| cov[line.size..-1] = ''} # remove extraneous character for end lines, in any
      bc
    end
  end
end
