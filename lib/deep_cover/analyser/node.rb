module DeepCover
  class Analyser::Node < Analyser
    def initialize(source, allow_uncovered: [], **options)
      super
      @allow_filters = Array(allow_uncovered).map{|kind| method(:"is_#{kind}?")}
    end

    def node_runs(node)
      runs = super
      if runs == 0 && @allow_filters.any?{ |f| f[node] }
        runs = nil
      end
      runs
    end

    # private
    def is_raise?(node)
      node.is_a?(Node::Send) && (node.method_name == :raise || node.method_name == :exit)
    end

    def is_default_argument?(node)
      node.parent.is_a?(Node::Optarg)
    end
  end
end
