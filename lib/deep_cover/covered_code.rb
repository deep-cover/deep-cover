module DeepCover
  class CoveredCode
    attr_accessor :covered_source, :buffer, :tracker_global, :local_var
    @@counter = 0
    @@globals = Hash.new{|h, global| h[global] = eval("#{global} ||= {}") }

    def initialize(path: nil, source: nil, lineno: nil, tracker_global: '$_cov', local_var: '_temp')
      raise "Must provide either path or source" unless path || source

      @buffer = ::Parser::Source::Buffer.new(path)
      if source
        @buffer.source = source
      else
        @buffer.read
      end
      @lineno = lineno
      @tracker_count = 0
      @tracker_global = tracker_global
      @local_var = local_var
      @covered_source = instrument_source
    end

    def nb_lines
      @nb_lines ||= begin
        lines = buffer.source_lines
        if lines.size == 0
          0
        else
          lines.size - (lines.last.empty? ? 1 : 0)
        end
      end
    end

    def execute_code(binding: DeepCover::GLOBAL_BINDING.dup)
      return if has_executed?
      global[nb] = Array.new(@tracker_count, 0)
      eval(@covered_source, binding, @buffer.name || '<raw_code>', @lineno || 1)
      self
    end

    def cover
      must_have_executed
      global[nb]
    end

    def line_coverage(**options)
      must_have_executed
      LineCoverageInterpreter.new(self, options).generate_results
    end

    def branch_cover
      must_have_executed
      BranchCoverageInterpreter.new(self).generate_results
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
      "#{tracker_global}[#{nb}][#{tracker_id}]+=1"
    end

    def trackers_setup_source
      "(#{tracker_global}||={})[#{nb}]||=Array.new(#{@tracker_count},0)"
    end

    def tracker_hits(tracker_id)
      cover.fetch(tracker_id)
    end

    def covered_ast
      @covered_ast ||= begin
        ast = Parser::CurrentRuby.new.parse(@buffer)
        return nil unless ast
        root = Node::Root.new(ast, self)
        root.main
      end
    end

    def each_node(*args, &block)
      return unless covered_ast
      covered_ast.each_node(*args, &block)
    end

    def instrument_source
      return '' unless covered_ast
      rewriter = ::Parser::Source::Rewriter.new(@buffer)
      covered_ast.each_node do |node|
        prefix, suffix = node.rewrite_prefix_suffix
        unless prefix.empty?
          expression = node.loc_hash[:expression]
          prefix = yield prefix, node, expression.begin, :prefix if block_given?
          rewriter.insert_before_multi expression, prefix rescue binding.pry
        end
        unless suffix.empty?
          expression = node.loc_hash[:expression]
          suffix = yield suffix, node, expression.end, :suffix if block_given?
          rewriter.insert_after_multi  expression, suffix
        end
      end
      rewriter.process
    end

    def has_executed?
      global[nb] != nil
    end

    protected
    def global
      @@globals[tracker_global]
    end

    def must_have_executed
      raise "cover for #{buffer.name} not available, file wasn't executed" unless has_executed?
    end
  end
end
