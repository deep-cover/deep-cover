module DeepCover
  class Node
    class Begin < Node
      has_extra_children expressions: Node

      def executed_loc_keys
        :begin
      end
    end
  end
end
