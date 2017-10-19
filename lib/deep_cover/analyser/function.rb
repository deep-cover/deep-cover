require_relative 'subset'

module DeepCover
  class Analyser::Function < Analyser
    include Analyser::Subset
    SUBSET_CLASSES = [Node::Block, Node::Defs, Node::Def]
  end
end
