require_relative 'node'

module DeepCover
  class AstRoot
    include HasTracker
    include HasChild

    has_tracker :root
    has_child main: Node, flow_entry_count: :root_tracker_hits, rewrite: -> {
      "#{covered_code.trackers_setup_source};%{root_tracker};%{node}"
    }
    attr_reader :covered_code, :children

    def initialize(child_ast, covered_code)
      @covered_code = covered_code
      @children = [child_ast] # Temporary set for augment
      @children = [self.class.augment(child_ast, covered_code, self)]
      super()
    end
  end
end
