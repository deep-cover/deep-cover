module DeepCover
  class Analyser::CoveredCodeSource < Analyser
    attr_reader :covered_code

    def initialize(covered_code)
      @covered_code = covered_code
    end

    # Looking exclusively at our subset of nodes, returns the node's direct descendants
    def node_children(node)
      node.children_nodes
    end

    # Returns the number of runs of the node (assumed to be in our subset)
    def node_runs(node)
      node.execution_count if node.executable?
    end

    module NodeExtension
      def to_analyser
        Analyser::CoveredCodeSource.new(covered_code)
      end
    end

    module CoveredCodeExtension
      def to_analyser
        Analyser::CoveredCodeSource.new(self)
      end
    end
  end
end
