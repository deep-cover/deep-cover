module DeepCover
  class Context
    attr_accessor :covered_source, :node_list, :buffer, :covered_ast
    @@counter = 0

    # TODO: Support non path based
    def initialize(path: nil, source: nil)
      raise "Must provide either path or source" unless path || source

      @buffer = ::Parser::Source::Buffer.new(path)
      if source
        @buffer.source = source
      else
        @buffer.read
      end
      @node_list = []
    end

    # Create a covered node from the argument
    def create(node, children)
      covered_node = Node.factory(node.type).new(node.type, children, location: node.location, context: self, nb: @node_list.size)
      @node_list.push(covered_node)
      covered_node
    end

    def cover
      return @cover if @cover
      $_cov ||= {}
      $_cov[nb] = @cover = Array.new(@node_list.size * 2, 0)
      eval(covered_source)
      @cover
    end

    def naive_coverage
      cover
      @naive_hits = Array.new(covered_source.lines.size)
      covered_ast.naive_cover
      @naive_hits
    end

    def naive_hit(line, runs = 1)
      @naive_hits[line] ||= 0
      @naive_hits[line] = [@naive_hits[line], runs].max
    end

    def branch_cover
      cover = buffer.source_lines.map{|line| ' ' * line.size}
      @node_list.each do |node|
        unless node.was_executed?
          bad = node.proper_range
          bad.each do |pos|
            cover[buffer.line_for_position(pos)-1][buffer.column_for_position(pos)] = node.executable? ? 'x' : '.'
          end
        end
      end
      cover
    end

    def nb
      @nb ||= (@@counter += 1)
    end
  end
end
