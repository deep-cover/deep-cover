require_relative 'variables'
require_relative 'collections'

module DeepCover
  class Node
    class Resbody < Node
      has_child exception: [Node::Array, nil]
      has_child assignment: [Lvasgn, nil]
      has_child body: [Node, nil]

      def suffix
        ";$_cov[#{file_coverage.nb}][#{nb*2}] += 1"
      end

      def flow_completion_count
        return body.flow_completion_count if body
        execution_count
      end

      def execution_count
        file_coverage.cover.fetch(nb*2)
      end

      def child_flow_entry_count(child)
        case child.index
        when EXCEPTION
          super
        when ASSIGNMENT
          file_coverage.cover.fetch(nb*2)
        when BODY
          file_coverage.cover.fetch(nb*2)
        end
      end
    end

    class Rescue < Node
      has_child watched_body: [Node, nil]
      has_extra_children resbodies: Resbody
      has_child else: [Node, nil]

      def flow_completion_count
        return super unless watched_body
        resbodies.map(&:flow_completion_count).inject(0, :+) + (self.else || watched_body).flow_completion_count
      end

      def execution_count
        return 0 unless self.else
        file_coverage.cover.fetch(nb*2)
      end

      def executable?
        !!self.else
      end

      def child_prefix(child)
        return if child.index != ELSE + children.size

        "$_cov[#{file_coverage.nb}][#{nb*2}]+=1;"
      end

      def child_flow_entry_count(child)
        case child.index
        when WATCHED_BODY
          super

        # TODO Better way to deal with rest children for this
        when *(0...children.size).to_a[RESBODIES]
          return 0 unless watched_body
          prev = child.previous_sibling

          if prev.index == WATCHED_BODY
            prev.flow_entry_count - prev.flow_completion_count
          else # RESBODIES
            # TODO is this okay?
            prev.exception.flow_completion_count - prev.execution_count
          end
        when ELSE + children.size
          return watched_body.flow_completion_count if watched_body
          super
        else
          binding.pry
        end
      end
    end

  end
end
