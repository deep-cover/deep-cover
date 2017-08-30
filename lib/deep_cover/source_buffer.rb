module DeepCover
  class SourceBuffer < ::Parser::Source::Buffer
    attr_accessor :ast, :covered_source, :node_list
    @@counter = 0

    def initialize(*)
      super
      @node_list = []
    end

    # Returns the node's number
    def register_node(node)
      @node_list.push(node)
      @node_list.size - 1
    end

    def cover
      return if @cover
      $_cov ||= {}
      $_cov[nb] = @cover = Array.new(@node_list.size, 0)
      eval(covered_source)
    end

    def coverage
      cover
      c0 = Array.new(covered_source.lines.size)
      @node_list.each do |node|
        ln = node.loc.expression.line - 1
        c0[ln] ||= 0
        c0[ln] = [c0[ln], @cover[node.nb]].max
      end
      c0
    end

    def nb
      @nb ||= (@@counter += 1)
    end
  end
end
