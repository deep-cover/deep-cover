# frozen_string_literal: true
require_relative 'subset'

module DeepCover
  class Analyser::Branch < Analyser
    include Analyser::Subset
    SUBSET_CLASSES = [Node::Branch]

    def results
      each_node.map do |node, _children|
        branches_runs = node.branches.map{|b| [b, node_runs(b)]}.to_h
        [node, branches_runs]
      end.to_h
    end

    def is_trivial_if?(node)
      parent = node.parent
      parent.is_a?(Node::If) && parent.condition.is_a?(Node::SingletonLiteral)
    end
  end
end
