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
          trees.inject do |result, h|
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
      end
    end
  end
end
