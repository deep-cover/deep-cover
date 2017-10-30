module DeepCover
  class Analyser::Node < Analyser
    def is_raise?(node)
      node.is_a?(Node::Send) && (node.message == :raise || node.message == :exit)
    end

    def is_default_argument?(node)
      node.parent.is_a?(Node::Optarg)
    end
  end
end
