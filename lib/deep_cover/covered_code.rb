module DeepCover
  class CoveredCode
    DEFAULT_TRACKER_GLOBAL = '$_cov'

    attr_accessor :covered_source, :buffer, :tracker_global, :local_var, :name
    @@counter = 0
    @@globals = Hash.new{|h, global| h[global] = eval("#{global} ||= {}") }

    def initialize(path: nil, source: nil, lineno: 1, tracker_global: DEFAULT_TRACKER_GLOBAL, local_var: '_temp', name: nil)
      raise "Must provide either path or source" unless path || source

      @buffer = ::Parser::Source::Buffer.new(path, lineno)
      @buffer.source = source ||= File.read(path)
      @tracker_count = 0
      @tracker_global = tracker_global
      @local_var = local_var
      @name = name || (source ? '(source)' : File.basename(path))
      @covered_source = instrument_source
    end

    def path
      @buffer.name || "(source: '#{@buffer.source[0..20]}...')"
    end

    def lineno
      @buffer.first_line
    end

    def nb_lines
      lines = buffer.source_lines
      if lines.size == 0
        0
      else
        lines.size - (lines.last.empty? ? 1 : 0)
      end
    end

    def execute_code(binding: DeepCover::GLOBAL_BINDING.dup)
      return if has_executed?
      global[nb] = Array.new(@tracker_count, 0)
      eval(@covered_source, binding, @buffer.name || '<raw_code>', lineno)
      self
    end

    def cover
      must_have_executed
      global[nb]
    end

    def line_coverage(**options)
      must_have_executed
      Analyser::PerLine.new(self, **options).results
    end

    def to_istanbul(**options)
      must_have_executed
      Reporter::Istanbul.new(self, **options).convert
    end

    def char_cover(**options)
      must_have_executed
      Analyser::PerChar.new(self, **options).results
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
      root.main
    end

    def root
      @root ||= begin
        ast = DeepCover.parser.parse(@buffer)
        Node::Root.new(ast, self)
      end
    end

    def each_node(*args, &block)
      covered_ast.each_node(*args, &block)
    end

    def instrument_source
      rewriter = ::Parser::Source::Rewriter.new(@buffer)
      covered_ast.each_node(:postorder) do |node|
        node.rewriting_rules.each do |range, rule|
          prefix, _node, suffix = rule.partition('%{node}')
          unless prefix.empty?
            prefix = yield prefix, node, range.begin, :prefix if block_given?
            rewriter.insert_before_multi range, prefix rescue binding.pry
          end
          unless suffix.empty?
            suffix = yield suffix, node, range.end, :suffix if block_given?
            rewriter.insert_after_multi  range, suffix
          end
        end
      end
      rewriter.process
    end

    def has_executed?
      global[nb] != nil
    end

    def lock
      must_have_executed
      unless @closed
        @closed = true
        covered_ast.each_node(&:freeze)
      end
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
