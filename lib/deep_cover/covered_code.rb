# frozen_string_literal: true

module DeepCover
  bootstrap
  load_parser

  class CoveredCode
    attr_accessor :covered_source, :buffer, :tracker_global, :local_var, :name
    @@counter = 0
    @@globals = Hash.new { |h, global| h[global] = eval("#{global} ||= {}") } # rubocop:disable Security/Eval

    def initialize(path: nil, source: nil, lineno: 1, tracker_global: DEFAULTS[:tracker_global], local_var: '_temp', name: nil)
      raise 'Must provide either path or source' unless path || source

      @buffer = Parser::Source::Buffer.new(path, lineno)
      @buffer.source = source || File.read(path)
      @tracker_count = 0
      @tracker_global = tracker_global
      @local_var = local_var
      @name = name.to_s || (path ? File.basename(path) : '(source)')
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
      if lines.empty?
        0
      else
        lines.size - (lines.last.empty? ? 1 : 0)
      end
    end

    def execute_code(binding: DeepCover::GLOBAL_BINDING.dup)
      return if has_executed?
      eval(@covered_source, binding, @buffer.name || '<raw_code>', lineno) # rubocop:disable Security/Eval
      self
    end

    def cover
      global[nb] ||= Array.new(@tracker_count, 0)
    end

    def line_coverage(**options)
      Analyser::PerLine.new(self, **options).results
    end

    def to_istanbul(**options)
      Reporter::Istanbul.new(self, **options).convert
    end

    def char_cover(**options)
      Analyser::PerChar.new(self, **options).results
    end

    def nb
      @nb ||= (@@counter += 1)
    end

    # Returns a range of tracker ids
    def allocate_trackers(nb_needed)
      prev = @tracker_count
      @tracker_count += nb_needed if nb_needed > 0 # Avoid error if frozen and called with 0.
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
        ast = parser.parse(@buffer)
        Node::Root.new(ast, self)
      end
    end

    def each_node(*args, &block)
      covered_ast.each_node(*args, &block)
    end

    def instrument_source
      rewriter = Parser::Source::TreeRewriter.new(@buffer)
      covered_ast.each_node(:postorder) do |node|
        node.rewriting_rules.each do |range, rule|
          prefix, _node, suffix = rule.partition('%{node}')
          prefix = yield prefix, node, range.begin, :prefix if block_given? && !prefix.empty?
          suffix = yield suffix, node, range.end, :suffix if block_given? && !suffix.empty?
          rewriter.wrap(range, prefix, suffix)
        end
      end
      rewriter.process
    end

    def has_executed?
      global[nb] != nil
    end

    def freeze
      unless frozen? # Guard against reentrance
        super
        root.each_node(&:freeze)
      end
      self
    end

    def inspect
      %{#<DeepCover::CoveredCode "#{name}">}
    end
    alias_method :to_s, :inspect

    protected

    def global
      @@globals[tracker_global]
    end

    private

    def parser
      Parser::CurrentRuby.new.tap do |parser|
        parser.diagnostics.all_errors_are_fatal = true
        parser.diagnostics.ignore_warnings      = true
      end
    end
  end
end
