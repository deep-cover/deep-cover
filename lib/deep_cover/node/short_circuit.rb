# frozen_string_literal: true

require_relative 'branch'

module DeepCover
  class Node
    class ShortCircuit < Node
      include Branch
      has_tracker :conditional
      has_child lhs: Node
      has_child conditional: Node, flow_entry_count: :conditional_tracker_hits,
                rewrite: '(%{conditional_tracker};%{node})'

      def branches
        [
          conditional,
          TrivialBranch.new(condition: lhs, other_branch: conditional),
        ]
      end

      def branches_summary(of_branches = branches)
        of_branches.map do |jump|
          if jump == conditional
            'right-hand side'
          else
            "#{type == :and ? 'falsy' : 'truthy'} shortcut"
          end
        end.join(' and ')
      end

      def operator
        loc_hash[:operator].source.to_sym
      end
    end

    class And < ShortCircuit
    end

    class Or < ShortCircuit
    end
  end
end
