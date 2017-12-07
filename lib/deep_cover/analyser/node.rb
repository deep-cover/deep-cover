# frozen_string_literal: true

module DeepCover
  class Analyser::Node < Analyser
    include Analyser::Subset

    def self.human_name
      'Nodes'
    end

    def initialize(source, ignore_uncovered: [], **options)
      @cache = {}.compare_by_identity
      super
      @allow_filters = Array(ignore_uncovered).map { |kind| method(:"is_#{kind}?") }
    end

    def node_runs(node)
      @cache.fetch(node) do
        runs = super
        runs = nil if runs == 0 && should_be_ignored?(node)
        @cache[node] = runs
      end
    end

    def is_raise?(node)
      node.is_a?(Node::Send) && (node.message == :raise || node.message == :exit)
    end

    def is_default_argument?(node)
      node.parent.is_a?(Node::Optarg)
    end

    def is_case_implicit_else?(node)
      parent = node.parent
      node.is_a?(Node::EmptyBody) && parent.is_a?(Node::Case) && !parent.has_else?
    end

    def in_subset?(node, _parent)
      node.executable?
    end

    def is_trivial_if?(node)
      # Supports only node being a branch or the fork itself
      node.parent.is_a?(Node::If) && node.parent.condition.is_a?(Node::SingletonLiteral)
    end

    def self.optionally_covered
      @optionally_covered ||= instance_methods(false).map do |method|
        method =~ /^is_(.*)\?$/
        Regexp.last_match(1)
      end.compact.map(&:to_sym).freeze
    end

    protected

    def convert(node, **)
      Analyser::CoveredCodeSource.new(node)
    end

    private

    def should_be_ignored?(node)
      @allow_filters.any? { |f| f[node] } || is_ignored?(node.parent)
    end

    def is_ignored?(node)
      if node == nil
        false
      elsif node.executable?
        node_runs(node).nil?
      else
        is_ignored?(node.parent)
      end
    end
  end
end
