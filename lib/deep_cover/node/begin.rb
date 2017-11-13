# frozen_string_literal: true
module DeepCover
  class Node
    class Begin < Node
      has_extra_children expressions: Node,
                         is_statement: true

      def is_statement
        false
      end

      def executed_loc_keys
        # Begin is a generic grouping used in different contexts.
        case loc_hash[:begin] && loc_hash[:begin].source
        when nil, '(', 'begin'
          []
        when 'else', '#{'
          %i[begin end]
        else
          warn "Unknown context for Begin node"
          []
        end
      end
    end
  end
end
