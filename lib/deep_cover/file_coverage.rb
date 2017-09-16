module DeepCover
  class FileCoverage
    attr_accessor :covered_source, :buffer, :covered_ast, :executed
    @@counter = 0

    # TODO: Support non path based
    def initialize(path: nil, source: nil, lineno: nil)
      raise "Must provide either path or source" unless path || source

      @buffer = ::Parser::Source::Buffer.new(path)
      if source
        @buffer.source = source
      else
        @buffer.read
      end
      @lineno = lineno
      @tracker_count = 0
      @covered_source = rewrite_source
    end

    def execute_file
      $_cov ||= {}
      $_cov[nb] = @cover = Array.new(@tracker_count, 0)
      execute_covered_source
    end

    def cover
      must_have_executed
      @cover
    end

    def line_coverage
      must_have_executed
      @line_hits = Array.new(covered_source.lines.size)
      covered_ast.line_cover
      @line_hits
    end

    def line_hit(line, flow_entry_count = 1)
      must_have_executed
      @line_hits[line] ||= 0
      @line_hits[line] = [@line_hits[line], flow_entry_count].max
    end

    def branch_cover
      must_have_executed
      bc = buffer.source_lines.map{|line| ' ' * line.size}
      @covered_ast.each_node do |node|
        unless node.was_executed?
          bad = node.proper_range
          bad.each do |pos|
            bc[buffer.line_for_position(pos)-1][buffer.column_for_position(pos)] = node.executable? ? 'x' : '-'
          end
        end
      end
      bc.zip(buffer.source_lines){|cov, line| cov[line.size..-1] = ''} # remove extraneous character for end lines, in any
      bc
    end

    def nb
      @nb ||= (@@counter += 1)
    end

    # Returns a range of tracker ids
    def allocate_trackers(nb_needed)
      prev = @tracker_count
      @tracker_count += nb_needed
      prev...@tracker_count
    end

    def tracker_source(tracker_id)
      "$_cov[#{nb}][#{tracker_id}]+=1"
    end

    def tracker_hits(tracker_id)
      cover.fetch(tracker_id)
    end

    def rewrite_source
      @covered_ast ||= begin
        ast = Parser::CurrentRuby.new.parse(@buffer)
        root = AstRoot.new(ast, self)
        root.main
      end

      rewriter = ::Parser::Source::Rewriter.new(@buffer)
      @covered_ast.each_node do |node|
        if prefix = node.full_prefix
          expression = node.loc.expression
          prefix = yield prefix, node, expression.begin, :prefix if block_given?
          rewriter.insert_before_multi expression, prefix
        end
        if suffix = node.full_suffix
          expression = node.loc.expression
          suffix = yield suffix, node, expression.end, :suffix if block_given?
          rewriter.insert_after_multi  expression, suffix
        end
      end
      rewriter.process
    end

    protected
    def must_have_executed
      raise "cover not available, file wasn't executed" unless @executed
    end

    def execute_covered_source
      # NOTE: the eval should be in a function alone, where no local variables are declared/used
      # Using Object.send(:binding) to make self be Object as require & load normally do.
      return if @executed
      @executed = true
      eval(@covered_source, Object.send(:binding), @buffer.name || '<raw_code>', @lineno || 1)
    end
  end
end
