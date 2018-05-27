# frozen_string_literal: true

require_relative 'subset'

module DeepCover
  class Analyser::Ruby25LikeBranch < Analyser
    def self.human_name
      'Ruby25 branches'
    end
    include Analyser::Subset
    SUBSET_CLASSES = [Node::Case, Node::Csend, Node::If, Node::ShortCircuit,
                      Node::Until, Node::UntilPost, Node::While, Node::WhilePost,
                     ].freeze

    def initialize(*args)
      super
      @loc_index = 0
    end

    def results
      extractor = NodeCoverageExtrator.new
      each_node.map do |node|
        extractor.branch_coverage(node)
      end.to_h
    end

    class NodeCoverageExtrator < SimpleDelegator
      def initialize(node = nil)
        self.node = node
        @loc_index = 0
      end

      alias_method :node=, :__setobj__
      alias_method :node, :__getobj__

      def branch_coverage(node)
        self.node = node
        case node
        when Node::Case
          handle_case
        when Node::Csend
          handle_csend
        when Node::If
          handle_if
        when Node::ShortCircuit
          handle_short_circuit
        when Node::Until, Node::While, Node::UntilPost, Node::WhilePost
          handle_until_while
        end
      end

      def handle_case
        cond_info = [:case, *node_loc_infos]

        sub_keys = [:when] * (branches.size - 1) + [:else]
        empty_fallbacks = whens.map { |w| (w.loc_hash[:begin] || w.loc_hash[:expression]).wrap_rwhitespace_and_comments.end }
        empty_fallbacks.map!(&:begin)

        if loc_hash[:else]
          empty_fallbacks << loc_hash[:end].begin
        else
          # DeepCover manually inserts a `else` for Case when there isn't one for tracker purposes.
          # The normal behavior of ruby25's branch coverage when there is no else is to return the loc of the node
          # So we sent that fallback.
          empty_fallbacks << expression
        end

        branches_locs = whens.map do |when_node|
          next when_node.body if when_node.body.is_a?(Node::EmptyBody)

          start_at = when_node.loc_hash[:begin]
          start_at = start_at.wrap_rwhitespace_and_comments.end if start_at
          start_at ||= when_node.body.expression.begin

          end_at = when_node.body.expression.end
          start_at.with(end_pos: end_at.end_pos)
        end

        branches_locs << node.else
        clauses_infos = infos_for_branches(branches_locs, sub_keys, empty_fallbacks, execution_counts: branches.map(&:execution_count))

        [cond_info, clauses_infos]
      end

      def handle_csend
        cond_info = [:"&.", *node_loc_infos]
        false_branch, true_branch = branches
        [cond_info, {[:then, *node_loc_infos] => true_branch.execution_count,
                     [:else, *node_loc_infos] => false_branch.execution_count,
                    },
        ]
      end

      def handle_if
        key = style == :unless ? :unless : :if

        node_range = extend_elsif_range
        cond_info = [key, *node_loc_infos(node_range)]

        sub_keys = [:then, :else]
        if style == :ternary
          empty_fallback_locs = [nil, nil]
        else
          else_loc = loc_hash[:else]

          first_clause_fallback = loc_hash[:begin]
          if first_clause_fallback
            first_clause_fallback = first_clause_fallback.wrap_rwhitespace_and_comments.end
          elsif else_loc
            first_clause_fallback = else_loc.begin
          end

          if else_loc
            second_clause_fallback = else_loc.wrap_rwhitespace_and_comments.end
          end
          end_loc = root_if_node.loc_hash[:end]
          end_loc = end_loc.begin if end_loc

          empty_fallback_locs = [first_clause_fallback || end_loc, second_clause_fallback || end_loc]
        end
        # loc can be nil if the clause can't be empty, such as ternary and modifer if/unless

        if key == :unless
          sub_keys.reverse!
          empty_fallback_locs.reverse!
        end

        branches_locs = branches
        execution_counts = branches_locs.map(&:execution_count)
        branches_locs[1] = extend_elsif_range(branches_locs[1])

        clauses_infos = infos_for_branches(branches_locs, sub_keys, empty_fallback_locs, execution_counts: execution_counts, node_range: node_range)
        [cond_info, clauses_infos]
      end

      def handle_short_circuit
        cond_info = [operator, *node_loc_infos]
        sub_keys = [:then, :else]
        sub_keys.reverse! if node.is_a?(Node::Or)

        [cond_info, infos_for_branches(branches, sub_keys, [nil, nil])]
      end

      def handle_until_while
        key = loc_hash[:keyword].source.to_sym
        base_info = [key, *node_loc_infos]
        body_node = if node.is_a?(Node::WhilePost) || node.is_a?(Node::UntilPost)
                      if body.instructions.present?
                        end_pos = body.instructions.last.expression.end_pos
                        body.instructions.first.expression.with(end_pos: end_pos)
                      else
                        body.loc_hash[:end].begin
                      end
                    elsif body.is_a?(Node::Begin) && node.body.expressions.present?
                      end_pos = body.expressions.last.expression.end_pos
                      body.expressions.first.expression.with(end_pos: end_pos)
                    else
                      body
                    end

        [base_info, {[:body, *node_loc_infos(body_node)] => body.execution_count}]
      end

      protected

      # If the actual else clause (final one) of an if...elsif...end is empty, then Ruby makes the
      # node reach the `end` in its branch coverage output
      def extend_elsif_range(node = self.node)
        if node.is_a?(Node::If) && node.style == :elsif
          deepest_if = node.deepest_elsif_node || node
          if deepest_if.false_branch.is_a?(Node::EmptyBody)
            return node.expression.with(end_pos: node.root_if_node.loc_hash[:end].begin_pos)
          end
        end
        node
      end

      def infos_for_branch(branch, key, empty_fallback_loc, execution_count: nil, node_range: node)
        if !branch.is_a?(Node::EmptyBody)
          loc = branch
        elsif branch.expression
          # There is clause, but it is empty
          loc = empty_fallback_loc
        else
          # There is no clause
          loc = node_range
        end

        execution_count ||= branch.execution_count
        [[key, *node_loc_infos(loc)], execution_count]
      end

      def infos_for_branches(branches, keys, empty_fallback_locs, execution_counts: [], node_range: node)
        branches_infos = branches.map.with_index do |branch, i|
          infos_for_branch(branch, keys[i], empty_fallback_locs[i], execution_count: execution_counts[i], node_range: node_range)
        end
        branches_infos.to_h
      end

      def node_loc_infos(source_range = node)
        source_range = source_range.expression if source_range.is_a?(Node)

        @loc_index += 1
        [@loc_index, source_range.line, source_range.column, source_range.last_line, source_range.last_column]
      end
    end
  end
end
