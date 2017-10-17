module DeepCover
  class Analyser::Node
    def initialize(covered_code, allow_uncovered: [], **)
      @covered_code = covered_code
      @allow_filters = Array(allow_uncovered).map{|kind| method(:"is_#{kind}?")}
    end

    # Returns a map of Node => runs
    def results
      @covered_code.each_node.map do |node|
        runs = node.execution_count
        if runs == 0 && @allow_filters.any?{ |f| f[node] }
          runs = nil
        end
        [node, runs]
      end.to_h
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
