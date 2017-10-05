module DeepCover
  class Node::Root < Node
    has_tracker :root
    has_child main: Node, flow_entry_count: :root_tracker_hits, rewrite: -> {
      "#{covered_code.trackers_setup_source};%{root_tracker};%{node}"
    }
    attr_reader :covered_code

    def initialize(child_ast, covered_code)
      @covered_code = covered_code
      super(nil, parent: nil, base_children: [child_ast])
    end
  end
end
