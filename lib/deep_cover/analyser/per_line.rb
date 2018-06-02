# frozen_string_literal: true

module DeepCover
  class Analyser::PerLine < Analyser
    # Returns an array of runs, one per line.
    def results
      disallow_partial = !options.fetch(:allow_partial, true)
      line_hits = Array.new(covered_code.nb_lines + covered_code.lineno - 1)
      each_node do |node|
        next unless (runs = node_runs(node))
        node.executed_locs.each do |loc|
          line_index = loc.line - 1
          if disallow_partial
            line_hits[line_index] = 0 if runs == 0
            next if line_hits[line_index] == 0
          end
          line_hits[line_index] = [line_hits[line_index] || 0, runs].max
        end
      end

      line_hits
    end
  end
end
