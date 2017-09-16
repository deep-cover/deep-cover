require_relative 'variables'
require_relative 'collections'

module DeepCover
  class Node
    class Resbody < Node
      has_tracker :exception_match
      has_child exception: [Node::Array, nil]
      has_child assignment: [Lvasgn, nil], flow_entry_count: :exception_match_tracker_hits
      has_child body: [Node, nil], flow_entry_count: :exception_match_tracker_hits

      def suffix
        ";#{exception_match_tracker_source}"
      end

      def flow_completion_count
        return body.flow_completion_count if body
        execution_count
      end

      def execution_count
        exception_match_tracker_hits
      end
    end

    class Rescue < Node
      has_tracker :else
      has_child watched_body: [Node, nil]
      has_extra_children resbodies: Resbody
      has_child else: [Node, nil], flow_entry_count: -> {watched_body.flow_completion_count if watched_body}

      def flow_completion_count
        return super unless watched_body
        resbodies.map(&:flow_completion_count).inject(0, :+) + (self.else || watched_body).flow_completion_count
      end

      def execution_count
        return 0 unless self.else
        else_tracker_hits
      end

      def executable?
        !!self.else
      end

      def child_prefix(child)
        return if child.index != ELSE + children.size

        "#{else_tracker_source};"
      end

      def resbodies_flow_entry_count(child)
        return 0 unless watched_body
        prev = child.previous_sibling

        if prev.index == WATCHED_BODY
          prev.flow_entry_count - prev.flow_completion_count
        else # RESBODIES
          # TODO is this okay?
          prev.exception.flow_completion_count - prev.execution_count
        end
      end
    end

  end
end
