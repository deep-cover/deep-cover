# frozen_string_literal: true

module DeepCover
  class Analyser::PerLine < Analyser
    # Returns an array of runs, one per line.
    # allow_partial can be one of:
    #   true: Allow any partial covering. Basically ruby's line coverage,
    #         if any thing is executed, it is considered executed
    #   branch: Only allow branches to be partially covered.
    #           if a node is not executed, the line has to be marked as not executed, even if part of it was.
    #   false: Allow nothing to be partially covered.
    #          same as :branch, but also:
    #          if an empty branch is not executed, the line has to be marked as not executed.
    #          This is only for empty branches because, if they are not empty, there will already
    #          be some red from the partial node covering. We don't want everything to become red,
    #          simply for 100% coverage to be as hard as branch + node coverage.
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
          disallowed_lines << line_index if !allow_partial && missed_empty_branch?(node)

          line_hits[line_index] = [line_hits[line_index] || 0, runs].max
        end
      end
      disallowed_lines.each { |line_index| line_hits[line_index] = 0 }
      line_hits
    end

    def missed_empty_branch?(node)
      node.is_a?(Node::Branch) && node.branches.any? { |b| b.is_a?(Node::EmptyBody) && node_runs(b) == 0 }
    end
  end
end
