# frozen_string_literal: true

module DeepCover
  module Reporter
    require_relative 'tree/util'

    class Base
      attr_reader :options

      def initialize(coverage, **options)
        @coverage = coverage
        @options = options
      end

      def analysis
        @analysis ||= Coverage::Analysis.new(@coverage.covered_codes, **options)
      end

      def each(&block)
        return to_enum :each unless block_given?
        @coverage.each do |covered_code|
          yield covered_code.name, covered_code
        end
        self
      end

      # Same as populate, but also yields data, which is either the analysis data (for leaves)
      # of the sum of the children (for subtrees)
      def populate_stats(&block)
        return to_enum(__method__) unless block_given?
        @map ||= analysis.stat_map.transform_keys(&:name)
        @tree ||= Tree::Util.paths_to_tree(@map.keys)
        Tree::Util.populate_from_map(
            tree: @tree,
            map: @map,
            merge: ->(child_data) { Tools.merge(*child_data, :+) },
            &block
        )
      end
    end
  end
end
