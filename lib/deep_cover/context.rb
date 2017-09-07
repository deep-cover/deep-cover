module DeepCover
  class Context
    attr_accessor :covered_source, :buffer, :covered_ast
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
      @node_count = 0
      rewrite
    end

    # Create a covered node from the argument
    def create(node, children)
      covered_node = Node.factory(node.type).new(node.type, children, location: node.location, context: self, nb: @node_count)
      @node_count += 1
      covered_node
    end

    def cover
      return @cover if @cover
      $_cov ||= {}
      $_cov[nb] = @cover = Array.new(@node_count * 2, 0)
      eval(covered_source)
      @cover
    end

    def line_coverage
      cover
      @line_hits = Array.new(covered_source.lines.size)
      covered_ast.line_cover
      @line_hits
    end

    def line_hit(line, runs = 1)
      @line_hits[line] ||= 0
      @line_hits[line] = [@line_hits[line], runs].max
    end

    def branch_cover
      cover
      bc = buffer.source_lines.map{|line| ' ' * line.size}
      @covered_ast.each_node do |node|
        unless node.was_executed?
          bad = node.proper_range
          bad.each do |pos|
            bc[buffer.line_for_position(pos)-1][buffer.column_for_position(pos)] = node.executable? ? 'x' : '-'
          end
        end
      end
      bc
    end

    def nb
      @nb ||= (@@counter += 1)
    end


    def augment(node)
      # Skip children that aren't node themselves (e.g. the `method` child of a :def node)
      return node unless node.is_a? ::Parser::AST::Node
      children = node.children.map{|child| augment(child)}
      create(node, children)
    end

    def rewrite
      ast = Parser::CurrentRuby.new.parse(@buffer)

      @covered_ast = augment(ast)
      rewriter = ::Parser::Source::Rewriter.new(@buffer)
      @covered_ast.each_node do |node|
        if prefix = node.prefix
          rewriter.insert_before_multi node.loc.expression, prefix
        end
        if suffix = node.suffix
          rewriter.insert_after_multi node.loc.expression, suffix
        end
      end
      @covered_source = rewriter.process
    end
  end
end
