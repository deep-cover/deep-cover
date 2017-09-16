require_relative 'node'

module DeepCover
  class AstRoot
    include HasTracker
    include HasChild

    has_tracker :root
    has_child main: Node, flow_entry_count: :root_tracker_hits, rewrite: "((%{root_tracker};%{node}))"

    attr_reader :covered_code

    def initialize(child_ast, covered_code)
      @covered_code = covered_code
      @main_node = Node.augment(child_ast, covered_code, self)
      super()
    end

    def children
      [@main_node]
    end
  end
end
