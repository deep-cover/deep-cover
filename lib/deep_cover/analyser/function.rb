module DeepCover
  class Analyser::Function
    attr_reader :node_runs

    def initialize(node_runs: nil, covered_code: (raise unless node_runs), **options)
      @node_runs = node_runs || Analyser::Node.new(covered_code, **options).results
    end

    FUNCTIONS = Set[Node::Block, Node::Defs, Node::Def]

    # Returns a map of Node => runs
    def results
      @node_runs.select{|node, _runs| is_function?(node) }
    end

    private
    def is_function?(node)
      FUNCTIONS.include? node.class
    end
  end
end
