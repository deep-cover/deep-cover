# frozen_string_literal: true

require_relative 'const'

module DeepCover
  class Node
    class ModuleName < Node
      has_child scope: [Node, nil]
      has_child const_name: Symbol

      def flow_completion_count
        parent.execution_count
      end

      def execution_count
        if scope
          scope.flow_completion_count
        else
          super
        end
      end
    end

    class Module < Node
      check_completion
      has_tracker :body_entry
      has_child const: {const: ModuleName}
      has_child body: Node,
                can_be_empty: -> { base_node.loc.end.begin },
                rewrite: '%{body_entry_tracker};%{local}=nil;%{node}',
                is_statement: true,
                flow_entry_count: :body_entry_tracker_hits
      executed_loc_keys :keyword

      def execution_count
        body_entry_tracker_hits
      end
    end

    class Class < Node
      check_completion
      has_tracker :body_entry
      has_child const: {const: ModuleName}
      has_child inherit: [Node, nil] # TODO
      has_child body: Node,
                can_be_empty: -> { base_node.loc.end.begin },
                rewrite: '%{body_entry_tracker};%{node}',
                is_statement: true,
                flow_entry_count: :body_entry_tracker_hits
      executed_loc_keys :keyword

      def execution_count
        body_entry_tracker_hits
      end
    end

    # class << foo
    class Sclass < Node
      has_child object: Node
      has_child body: Node,
                can_be_empty: -> { base_node.loc.end.begin },
                is_statement: true
      # TODO
    end
  end
end
