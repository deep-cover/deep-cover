# frozen_string_literal: true

module DeepCover
  class Node::Root < Node
    has_tracker :root
    has_child main: Node,
              can_be_empty: -> { Parser::Source::Range.new(covered_code.buffer, 0, 0) },
              is_statement: true,
              rewrite: -> {
                "#{covered_code.trackers_setup_source};%{root_tracker};%{local}=nil;%{node}"
              }
    attr_reader :covered_code
    alias_method :flow_entry_count, :root_tracker_hits

    def initialize(child_ast, covered_code)
      @covered_code = covered_code
      super(nil, parent: nil, base_children: [child_ast])
    end
  end
end
