# frozen_string_literal: true

module DeepCover
  module Reporter
    module Util
      # Utility functions to deal with trees
      module Tree
        def paths_to_tree(paths)
          twigs = paths.map do |path|
            partials = path_to_partial_paths(path)
            list_to_twig(partials)
          end
          tree = deep_merge(twigs)
          simplify(tree)
        end

        # 'some/example/path' => %w[some example path]
        def path_to_partial_paths(path)
          path.to_s.split('/')
        end

        # A twig is a tree with only single branches
        # [a, b, c] =>
        #   {a: {b: {c: {} } } }
        def list_to_twig(items)
          result = {}
          items.inject(result) do |parent, value|
            parent[value] = {}
          end
          result
        end

        #   [{a: {b: {c: {} } } }
        #    {a: {b: {d: {} } } }]
        # => {a: {b: {c: {}, d: {} }}}
        def deep_merge(trees)
          trees.inject({}) do |result, h|
            result.merge(h) { |k, val, val_b| deep_merge([val, val_b]) }
          end
        end

        # {a: {b: {c: {}, d: {} }}}
        # => {a/b: {c: {}, d: {} }}
        def simplify(tree)
          tree.map do |key, sub_tree|
            sub_tree = simplify(sub_tree)
            if sub_tree.size == 1
              key2, sub_tree = sub_tree.first
              key = "#{key}/#{key2}"
            end
            [key, sub_tree]
          end.to_h
        end

        # {a: {b: {}}}    => [ra, rb]
        # where rb = yield('a/b', 'b', [])
        # and ra = yield('a', 'a', [rb])
        def populate(tree, dir = '', &block)
          return to_enum(__method__, tree, dir) unless block_given?
          tree.map do |path, children_hash|
            full_path = [dir, path].join
            children = populate(children_hash, "#{full_path}/", &block)
            yield full_path, path, children
          end
        end

        # Same as populate, but also yields data, which is either the analysis data (for leaves)
        # of the sum of the children (for subtrees)
        def populate_stats(analysis)
          return to_enum(__method__, analysis) unless block_given?
          map = analysis.stat_map.transform_keys(&:name)
          tree = paths_to_tree(map.keys)
          final_results, _final_data = populate(tree) do |full_path, partial_path, children|
            if children.empty?
              data = map[full_path]
            else
              child_results, child_data = children.transpose
              data = Tools.merge(*child_data, :+)
            end
            result = yield full_path, partial_path, data, child_results || []
            [result, data]
          end.transpose
          final_results
        end
      end
    end
  end
end
