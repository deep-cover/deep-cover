# frozen_string_literal: true

module DeepCover
  class Analyser::PerChar < Analyser
    def self.human_name
      'Chars'
    end

    # Returns an array of characters for each line of code.
    # Each character is either ' ' (executed), '-' (not executable) or 'x' (not covered)
    def results
      bc = buffer.source_lines.map { |line| '-' * line.size }
      each_node do |node|
        runs = node_runs(node)
        next if runs == nil
        node.proper_range.each do |pos|
          bc[buffer.line_for_position(pos) - buffer.first_line][buffer.column_for_position(pos)] = runs > 0 ? ' ' : 'x'
        end
      end
      bc.zip(buffer.source_lines) { |cov, line| cov[line.size..-1] = '' } # remove extraneous character for end lines, in any
      bc
    end

    def node_stat_contribution(node)
      node.executed_locs.sum(&:size)
    end

    def stats
      s = super
      actual_total = buffer.source.size
      s.with not_executable: actual_total - s.total
    end

    def buffer
      covered_code.buffer
    end
  end
end
