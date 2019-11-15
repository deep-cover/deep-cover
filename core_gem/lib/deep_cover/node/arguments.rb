# frozen_string_literal: true

require_relative 'assignments'

module DeepCover
  class Node
    class Arg < Node
      has_child name: Symbol
      def executable?
        false
      end
    end
    Kwarg = Arg

    class Restarg < Node
      has_child name: [Symbol, nil]
      def executable?
        false
      end
    end
    Kwrestarg = Restarg

    class Optarg < Node
      has_tracker :default
      has_child name: Symbol
      has_child default: Node, flow_entry_count: :default_tracker_hits

      # Default child rewriting rule
      def rewrite_default
        if parent.children.size >= 32 && RUBY_VERSION >= '2.3' && RUBY_VERSION < '2.6'
          # Workaround for Ruby bugs when too many default arguments are present
          # This will ignore some cases which would not create issues, but its rare enough to have
          # 32 arguments to a method that I don't care.
          # https://github.com/deep-cover/deep-cover/issues/47#issuecomment-477176061
          return
        end
        '(%{default_tracker};%{node})'
      end

      def executable?
        false
      end
    end
    Kwoptarg = Optarg

    # foo(&block)
    class Blockarg < Node
      has_child name: Symbol

      def executable?
        false
      end
    end

    class Args < Node
      has_extra_children arguments: [Arg, Optarg, Restarg, Kwarg, Kwoptarg, Kwrestarg, Blockarg, Mlhs]

      def executable?
        false
      end
    end
  end
end
