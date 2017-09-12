require 'backports/2.1.0/enumerable/to_h'

module DeepCover
  class AstRoot
    attr_reader :context, :nb

    def initialize(context)
      @context = context
      @nb = context.create_node_nb
    end

    def child_runs(_child)
      context.cover.fetch(nb*2)
    end

    def child_prefix(_child)
      "(($_cov[#{context.nb}][#{nb*2}] += 1;"
    end

    def child_suffix(_child)
      "))"
    end
  end
end
