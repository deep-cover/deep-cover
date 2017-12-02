# frozen_string_literal: true

module DeepCover
  class Analyser::Node < Analyser
    include Analyser::Subset

    def is_raise?(node)
      node.is_a?(Node::Send) && (node.message == :raise || node.message == :exit)
    end

    def is_default_argument?(node)
      node.parent.is_a?(Node::Optarg)
    end

    def is_case_implicit_else?(node)
      parent = node.parent
      node.is_a?(Node::EmptyBody) && parent.is_a?(Node::Case) && !parent.has_else?
    end

    def in_subset?(node, _parent)
      node.executable?
    end

    protected

    def convert(node, **)
      Analyser::CoveredCodeSource.new(node)
    end
  end
end
