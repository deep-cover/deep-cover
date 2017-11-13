# frozen_string_literal: true

module DeepCover
  class Node
    class Splat < Node
      check_completion inner: '[%{node}]', outer: '*%{node}'
      has_child receiver: Node
    end

    class Kwsplat < Node
      check_completion inner: '{%{node}}', outer: '**%{node}'
      has_child receiver: Node
    end
  end
end
