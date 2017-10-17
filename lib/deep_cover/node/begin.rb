module DeepCover
  class Node
    class Begin < Node
      has_extra_children expressions: Node,
                         is_statement: true

      def is_statement
        false
      end

      def executed_loc_keys
        # For now, we want the end of #{...} to match its begin
        [:begin, (:end unless loc_hash[:end] && loc_hash[:end].source == 'end' )]
      end
    end
  end
end
