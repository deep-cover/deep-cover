module DeepCover
  module Analyser::Base
    attr_reader :source, :options

    def initialize(source, **options)
      @source = source.to_analyser
      @options = options
    end

    # Basic coercion mechanism
    def to_analyser
      self
    end

    # Looking exclusively at our subset of nodes, returns the node's direct descendants
    def node_children(node)
      @source.node_children(node)
    end

    # Returns the number of runs of the node (assumed to be in our subset)
    def node_runs(node)
      @source.node_runs(node)
    end

    def node_runs_map
      each_node.map do |node, sub_statements|
        [node, node_runs(node)]
      end.to_h
    end

    # Analyser-specific output
    def results
      node_runs_map
    end

    # Iterates on nodes in the subset.
    # Yields the node and it's children (within the subset)
    def each_node(from = covered_code.root, &block)
      return to_enum(:each_node) unless block_given?
      children = node_children(from)
      yield from, children unless from.is_a?(Node::Root)
      children.each do |child|
        each_node(child, &block)
      end
    end

    def covered_code
      @source.covered_code
    end
  end
end
