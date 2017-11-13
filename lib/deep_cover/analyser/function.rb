# frozen_string_literal: true

require_relative 'subset'

module DeepCover
  class Analyser::Function < Analyser
    include Analyser::Subset
    SUBSET_CLASSES = [Node::Block, Node::Defs, Node::Def].freeze

    def node_runs(node)
      super(node.body)
    end
  end
end
