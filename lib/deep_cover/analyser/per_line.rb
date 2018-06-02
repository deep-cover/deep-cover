# frozen_string_literal: true

module DeepCover
  class Analyser::PerLine < Analyser
    # Returns an array of runs, one per line.
    def results
      allow_partial = options.fetch(:allow_partial, true)
      line_hits = Array.new(covered_code.nb_lines + covered_code.lineno - 1)
      disallowed_lines = Set.new
      each_node do |node|
        next unless (runs = node_runs(node))
        node.executed_locs.each do |loc|
          line_index = loc.line - 1

          next if disallowed_lines.include?(line_index)
          disallowed_lines << line_index if [nil, false, :branch].include?(allow_partial) && runs == 0

          line_hits[line_index] = [line_hits[line_index] || 0, runs].max
        end
      end
      disallowed_lines.each { |line_index| line_hits[line_index] = 0 }
      line_hits
    end
  end
end
