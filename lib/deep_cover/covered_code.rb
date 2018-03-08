# frozen_string_literal: true

module DeepCover
  bootstrap
  load_parser

  class CoveredCode
    attr_accessor :covered_source, :buffer, :tracker_list, :local_var, :path

    def initialize(
      path: nil,
      source: nil,
      lineno: 1,
      tracker_global: DEFAULTS[:tracker_global],
      tracker_list: TrackerList.new(TrackerBucket[tracker_global]),
      local_var: '_temp'
    )
      raise 'Must provide either path or source' unless path || source

      @path = path &&= Pathname(path)
      @buffer = Parser::Source::Buffer.new('', lineno)
      @buffer.source = source || path.read
      @tracker_count = 0
      @tracker_list = tracker_list
      @local_var = local_var
      @covered_source = instrument_source
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
      eval(@covered_source, binding, (@path || '<raw_code>').to_s, lineno) # rubocop:disable Security/Eval
      self
    end

    def cover
      global[nb] ||= Array.new(@tracker_count, 0)
    end

    def line_coverage(**options)
      Analyser::PerLine.new(self, **options).results
    end

    def char_cover(**options)
      Analyser::PerChar.new(self, **options).results
    end

    def tracker_hits(tracker_id)
      cover.fetch(tracker_id)
    end

    def covered_ast
      root.main
    end

    def comments
      root
      @comments
    end

    def root
      @root ||= begin
        ast, @comments = parser.parse_with_comments(@buffer)
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

    def freeze
      unless frozen? # Guard against reentrance
        super
        root.each_node(&:freeze)
      end
      self
    end

    def inspect
      %{#<DeepCover::CoveredCode "#{path}">}
    end
    alias_method :to_s, :inspect

    private

    def parser
      Parser::CurrentRuby.new.tap do |parser|
        parser.diagnostics.all_errors_are_fatal = true
        parser.diagnostics.ignore_warnings      = true
      end
    end
  end
end
