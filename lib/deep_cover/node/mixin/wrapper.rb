module DeepCover
  module Node::Mixin
    module Wrapper
      def initialize(base_node, **kwargs)
        super(base_node, base_children: [base_node], **kwargs)
      end
    end
  end
end
