# frozen_string_literal: true

module DeepCover
  module Analyser::Base
    include Tools::Covered

    attr_reader :source, :options

    def initialize(source, **options)
      @source = to_source(source, **options)
      @options = options
    end

    # Looking exclusively at our subset of nodes, returns the node's direct descendants
    def node_children(node)
      @source.node_children(node)
    end

    # Returns the number of runs of the node (assumed to be in our subset)
    def node_runs(node)
      @source.node_runs(node)
    end

    def node_covered?(node)
      covered?(node_runs(node))
    end

    def node_runs_map
      each_node.map do |node|
        [node, node_runs(node)]
      end.to_h
    end

    # Analyser-specific output
    def results
      node_runs_map
    end

    def node_stat_type(node)
      return :not_executable unless node.executable?
      case node_runs(node)
      when nil
        :ignored
      when 0
        :not_executed
      else
        :executed
      end
    end

    def node_stat_contributions(nodes)
      if respond_to? :node_stat_contribution
        nodes.sum { |n| node_stat_contribution(n) }
      else
        nodes.size
      end
    end

    def stats
      st = each_node.group_by { |n| node_stat_type(n) }
                    .transform_values { |nodes| node_stat_contributions(nodes) }
      Analyser::Stats.new(**st)
    end

    # Iterates on nodes in the subset.
    # Yields the node and it's children (within the subset)
    def each_node(from = covered_code.root, &block)
      return to_enum(:each_node) unless block_given?
      begin
        yield from unless from.is_a?(Node::Root)
      rescue ProblemWithDiagnostic
        raise
      rescue StandardError, SystemStackError => e
        raise ProblemWithDiagnostic.new(covered_code, from.diagnostic_expression, e)
      end
      node_children(from).each do |child|
        each_node(child, &block)
      end
    end

    def covered_code
      @source.covered_code
    end

    protected

    def convert(covered_code, **options)
      Analyser::Node.new(covered_code, **options)
    end

    def to_source(source, **options)
      case source
      when Analyser
        source
      when CoveredCode
        convert(source, **options)
      when Node
        convert(source.covered_code, **options)
      else
        raise ArgumentError, "expected Analyser, Node or CoveredCode, got #{source.class}"
      end
    end
  end
end
