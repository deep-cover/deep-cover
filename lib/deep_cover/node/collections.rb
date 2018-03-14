# frozen_string_literal: true

require_relative 'splat'

module DeepCover
  class Node
    module SimpleIfEmpty
      def simple_literal?
        children.empty?
      end
    end

    class Array < Node
      include SimpleIfEmpty
      has_extra_children elements: Node
      executed_loc_keys :begin, :end
    end

    class Pair < Node
      has_child key: Node
      has_child value: Node
      executed_loc_keys :operator
    end

    class Hash < Node
      include SimpleIfEmpty
      has_extra_children elements: [Pair, Kwsplat]
      executed_loc_keys :begin, :end
    end
  end
end
