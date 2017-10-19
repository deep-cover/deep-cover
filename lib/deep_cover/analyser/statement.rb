require_relative 'subset'

module DeepCover
  class Analyser::Statement < Analyser
    include Analyser::Subset
    # Returns a map of Range => runs
    def results
      each_node.flat_map do |node, sub_statements|
        shatter(node, sub_statements).map{|r| [r, node_runs(node)]}
      end.to_h
    end

    private

    # returns a list of [proper_range, node], where
    # the nodes may be repeating, the proper_ranges are non-intersecting but non ordered.
    def shatter(node, sub_statements)
      subs = sub_statements.map{|n| n.loc_hash[:expression]}.compact
      range = node.loc_hash[:expression]
      subs.reject!{|r| r.disjoint?(range) } # This is the case iff using heredocs
      proper = range.split(*subs)
      proper.map!{|r| r.lstrip(/(\s*#.*\n)+/) }  # Strip comment blocks
      proper.map!{|r| r.strip(/[^a-zA-Z0-9'"\[\]{}_:$]*/) } # Ignore whitespace & punctuation
      proper.reject!(&:empty?)
      proper.reject!{|r| r.source == 'end' || r.source == '}'}
      proper
    end

    def in_subset?(node, parent)
      is_statement = node.is_statement
      if node.loc_hash[:expression].nil?
        false
      elsif is_statement != :if_incompatible
        is_statement
      else
        !compatible_runs?(node_runs(parent), node_runs(node))
      end
    end

    def compatible_runs?(expression_runs, sub_expression_runs)
      sub_expression_runs.nil? ||
        (sub_expression_runs == 0) == (expression_runs == 0)
    end
  end
end
