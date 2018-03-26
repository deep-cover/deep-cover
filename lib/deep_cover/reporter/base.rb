# frozen_string_literal: true

module DeepCover
  module Reporter
    require_relative 'tree/util'

    class Base
      include Memoize
      memoize :map, :tree, :root_path

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
          yield relative_path(covered_code.path), covered_code
        end
        self
      end

      # Same as populate, but also yields data, which is either the analysis data (for leaves)
      # of the sum of the children (for subtrees)
      def populate_stats
        return to_enum(__method__) unless block_given?
        Tree::Util.populate_from_map(
            tree: tree,
            map: map,
            merge: ->(child_data) { Tools.merge(*child_data, :+) }
        ) do |full_path, partial_path, data, children|
          yield relative_path(full_path), relative_path(partial_path), data, children
        end
      end

      private

      def relative_path(path)
        path = path.to_s
        path = path.slice(root_path.length + 1..-1) if path.start_with?(root_path)
        path
      end

      def root_path
        return '' if tree.size > 1
        path = tree.first.first
        root = File.dirname(path)
        root = File.dirname(root) if File.basename(path) == 'dir'
        root
      end

      def map
        analysis.stat_map.transform_keys(&:path).transform_keys(&:to_s)
      end

      def tree
        Tree::Util.paths_to_tree(map.keys)
      end
    end
  end
end
