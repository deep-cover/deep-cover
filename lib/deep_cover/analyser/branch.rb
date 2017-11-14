# frozen_string_literal: true

require_relative 'subset'

module DeepCover
  class Analyser::Branch < Analyser
    include Analyser::Subset
    SUBSET_CLASSES = [Node::Branch].freeze

    def node_stat_type(node)
      type = super
      type = :not_executed unless type == :ignored || fully_executed?(node)
      type
    end

    def results
      # Note: we also ask ourselves for the node runs of branches
      each_node.map do |node|
        branches_runs = node.branches.map { |b| [b, node_runs(b)] }.to_h
        [node, branches_runs]
      end.to_h
    end

    def is_trivial_if?(node)
      # Supports only node being a branch or the fork itself
      node.parent.is_a?(Node::If) && node.parent.condition.is_a?(Node::SingletonLiteral)
    end

    private

    def fully_executed?(fork)
      fork.branches.all? { |jump| source.node_runs(jump) != 0 }
    end
  end
end
