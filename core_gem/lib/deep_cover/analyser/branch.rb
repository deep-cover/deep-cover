# frozen_string_literal: true

require_relative 'subset'

module DeepCover
  class Analyser::Branch < Analyser
    def self.human_name
      'Branches'
    end
    include Analyser::Subset
    SUBSET_CLASSES = [Node::Branch].freeze

    def node_runs(node)
      runs = super
      if node.is_a?(Node::Branch) && covered?(runs)
        worst = worst_branch_runs(node)
        runs = worst unless covered?(worst)
      end
      runs
    end

    def results
      each_node.map do |node|
        branches_runs = node.branches.map { |jump| [jump, branch_runs(jump)] }.to_h
        [node, branches_runs]
      end.to_h
    end

    private

    def worst_branch_runs(fork)
      fork.branches.map { |jump| branch_runs(jump) }
          .min_by { |runs| runs == 0 ? -2 : runs || -1 }
    end

    def branch_runs(branch)
      branch.flow_entry_count.nonzero? || source.node_runs(branch)
    end
  end
end
