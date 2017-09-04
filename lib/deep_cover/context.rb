module DeepCover
  class Context
    attr_accessor :ast, :covered_source, :node_list, :buffer
    @@counter = 0

    # TODO: Support non path based
    def initialize(path)
      @buffer = ::Parser::Source::Buffer.new(path)
      @buffer.read
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

    def coverage
      cover
      hits = Array.new(covered_source.lines.size)
      @node_list.each do |node|
        next unless ex = node.loc.expression
        ln = ex.line - 1
        hits[ln] ||= 0
        hits[ln] = [hits[ln], node.runs].max
      end
      hits
    end

    def branch_cover
      cover = buffer.source_lines.map{|line| ' ' * line.size}
      @node_list.each do |node|
        unless node.was_called?
          bad = node.proper_range
          bad.each do |pos|
            cover[buffer.line_for_position(pos)-1][buffer.column_for_position(pos)] = node.callable? ? 'x' : '.'
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
