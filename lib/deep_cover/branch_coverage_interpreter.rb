
module DeepCover
  # This is not actually branch coverage, but we call it like that everything.
  # This is more like atom coverage.
  # To be renamed, along with the rest.
  class BranchCoverageInterpreter
    def initialize(covered_code)
      @covered_code = covered_code
    end

    def generate_results
      check_node_overlap

      buffer = @covered_code.buffer
      bc = buffer.source_lines.map{|line| '-' * line.size}
      @covered_code.covered_ast.each_node do |node|
        if node.executable?
          node.proper_range.each do |pos|
            bc[buffer.line_for_position(pos)-1][buffer.column_for_position(pos)] = node.was_executed? ? ' ' : 'x'
          end
        end
      end
      bc.zip(buffer.source_lines){|cov, line| cov[line.size..-1] = ''} # remove extraneous character for end lines, in any
      bc
    end

    # For now, when an overlap is found, just open a binding.pry to make fixing it easier.
    def check_node_overlap
      node_to_positions = {}
      @covered_code.covered_ast.each_node do |node|
        node.proper_range.each do |position|
          if node_to_positions[position]
            already = node_to_positions[position]
            puts "There is a proper_range overlap between #{node} and #{already}"
            puts "Overlapping: #{already.proper_range & node.proper_range}"
            binding.pry
          end
          node_to_positions[position] = node
        end
      end
    end
  end
end
