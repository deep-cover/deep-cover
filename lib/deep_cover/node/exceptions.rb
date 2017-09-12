module DeepCover
  class Node
    class Rescue < Node
      has_children :watched_body, :resbodies__rest, :else

      def full_runs
        return super unless watched_body
        resbodies.map(&:full_runs).sum + (self.else || watched_body).full_runs
      end

      def child_runs(child)
        case child.index
        when WATCHED_BODY
          super

        # TODO Better way to deal with rest children for this
        when *(0...children.size).to_a[RESBODIES]
          return 0 unless watched_body
          prev = child.previous_sibbling

          if prev.index == WATCHED_BODY
            prev.runs - prev.full_runs
          else # RESBODIES
            # TODO is this okay?
            prev.exception.full_runs - prev.proper_runs
          end
        when ELSE
          return watched_body.full_runs if watched_body
          super
        else
          binding.pry
        end
      end
    end


    class Resbody < Node
      has_children :exception, :assignment, :body

      def suffix
        ";$_cov[#{context.nb}][#{nb*2}] += 1"
      end

      def full_runs
        return body.full_runs if body
        proper_runs
      end

      def proper_runs
        context.cover.fetch(nb*2)
      end

      def child_runs(child)
        case child.index
        when EXCEPTION
          super
        when ASSIGNMENT
          context.cover.fetch(nb*2)
        when BODY
          context.cover.fetch(nb*2)
        end
      end
    end
  end
end
