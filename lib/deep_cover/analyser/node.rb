module DeepCover
  class Analyser::Node < Analyser
    def is_raise?(node)
      node.is_a?(Node::Send) && (node.method_name == :raise || node.method_name == :exit)
    end

    def is_default_argument?(node)
      node.parent.is_a?(Node::Optarg)
    end
  end
end
