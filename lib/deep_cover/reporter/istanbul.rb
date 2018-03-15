# frozen_string_literal: true

require 'json'

module DeepCover
  module Reporter
    class Istanbul < Struct.new(:covered_code, :options)
      # Converters has no dependency on the including class.
      module Converters
        def convert_range(range)
          {start: {
                    line: range.line,
                    column: range.column,
                  },
           end: {
                  line: range.last_line,
                  column: range.last_column - 1, # Our ranges are exclusive, Istanbul's are inclusive
                },
          }
        end

        # [:a, :b, :c] => {'1': :a, '2': :b, '3': :c}
        def convert_list(list)
          list.map.with_index { |val, i| [i.succ.to_s, val] }.to_h
        end

        def convert_def(node)
          ends_at = node.signature.loc_hash[:end] || node.loc_hash[:name]
          decl = node.loc_hash[:keyword].with(end_pos: ends_at.end_pos)
          _convert_function(node, node.method_name, decl)
        end

        def convert_block(node)
          decl = node.loc_hash[:begin]
          if (args = node.args.expression)
            decl = decl.join(args)
          end
          _convert_function(node, '(block)', decl)
        end

        def convert_function(node)
          if node.is_a?(Node::Block)
            convert_block(node)
          else
            convert_def(node)
          end
        end

        def convert_branch(node, branches = node.branches)
          # Currently, nyc seems to outputs the same location over and over...
          {
            loc: convert_range(node.expression),
            type: node.type,
            line: node.expression.line,
            locations: branches.map { |n| convert_range(n.expression || node.expression) },
          }
        end

        private

        def _convert_function(node, name, decl)
          loc = node.body ? node.body.expression : decl.end
          {
            name: name,
            line: node.expression.line,
            decl: convert_range(decl),
            loc:  convert_range(loc),
          }
        end
      end
      include Converters

      def node_analyser
        @node_analyser ||= Analyser::Node.new(covered_code, **options)
      end

      def node_runs
        @node_runs ||= node_analyser.results
      end

      def functions
        @functions ||= Analyser::Function.new(node_analyser, **options).results
      end

      def statements
        @statements ||= Analyser::Statement.new(node_analyser, **options).results
      end

      def branches
        @branches ||= Analyser::Branch.new(node_analyser, **options).results
      end

      def branch_map
        branches.map do |node, branches_runs|
          convert_branch(node, branches_runs.keys)
        end
      end

      # Istanbul doesn't understand how to ignore a branch...
      def zero_to_something(values)
        values.map { |v| v || 1 }
      end

      def branch_runs
        branches.values.map { |r| zero_to_something(r.values) }
      end

      def statement_map
        statements.keys.map { |range| convert_range(range) }
      end

      def statement_runs
        statements.values
      end

      def function_map
        functions.keys.map { |n| convert_function(n) }
      end

      def function_runs
        functions.values
      end

      def data
        {
          statementMap: statement_map,
          s:            statement_runs,
          fnMap:        function_map,
          f:            function_runs,
          branchMap:    branch_map,
          b:            branch_runs,
        }
      end

      def convert
        {covered_code.name => {
                                path: covered_code.path,
                                **data.transform_values { |l| convert_list(l) },
                              },
        }
      end

      class << self
        def available?
          `nyc --version` >= '11.' rescue false
        end
      end
    end
  end
end
