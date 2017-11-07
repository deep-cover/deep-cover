module DeepCover
  class Analyser::CoveredCodeSource < Analyser
    attr_reader :covered_code

    def initialize(covered_code)
      @covered_code = covered_code.freeze
    end

    # Looking exclusively at our subset of nodes, returns the node's direct descendants
    def node_children(node)
      node.children_nodes
    end

    # Returns the number of runs of the node (assumed to be in our subset)
    def node_runs(node)
      node.execution_count if node.executable?
    end
  end
end
