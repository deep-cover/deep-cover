require_relative 'subset'

module DeepCover
  class Analyser::Statement < Analyser
    include Analyser::Subset
    # Returns a map of Range => runs
    def results
      each_node.map do |node, _sub_statements|
        [node.expression, node_runs(node)]
      end.to_h
    end

    private

    def in_subset?(node, parent)
      is_statement = node.is_statement
      if node.expression.nil?
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
