# frozen_string_literal: true

module DeepCover
  class Analyser::Node < Analyser
    include Analyser::Subset

    def self.human_name
      'Nodes'
    end

    def initialize(source, **options)
      @cache = {}.compare_by_identity
      super
      @allow_filters = Config.options_to_ignored(**options)
                             .map { |kind| Node.filter_to_method_name(kind) }
      @nocov_ranges = FlagCommentAssociator.new(covered_code)
    end

    def node_runs(node)
      @cache.fetch(node) do
        runs = super
        runs = nil if runs == 0 && should_be_ignored?(node)
        @cache[node] = runs
      end
    end

    def in_subset?(node, _parent)
      node.executable?
    end

    protected

    def convert(node, **)
      Analyser::CoveredCodeSource.new(node)
    end

    private

    def should_be_ignored?(node)
      @nocov_ranges.include?(node) ||
        @allow_filters.any? { |f| node.public_send(f) } ||
        is_ignored?(node.parent)
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
