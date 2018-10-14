# frozen_string_literal: true

module DeepCover
  bootstrap
  load_parser

  class CoveredCode
    attr_accessor :buffer, :tracker_storage, :local_var, :path

    def initialize(
      path: nil,
      source: nil,
      lineno: 1,
      tracker_global: DEFAULTS[:tracker_global],
      tracker_storage: TrackerBucket[tracker_global].create_storage,
      local_var: '_temp'
    )
      raise 'Must provide either path or source' unless path || source

      @path = path &&= Pathname(path)
      @buffer = Parser::Source::Buffer.new('', lineno)
      @buffer.source = source || path.read
      @tracker_storage = tracker_storage
      @local_var = local_var
      @covered_source = nil
      # We parse the code now so that problems happen early
      covered_ast
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
      eval(covered_source, binding, (@path || '<raw_code>').to_s, lineno) # rubocop:disable Security/Eval
      self
    end

    def execute_code_or_warn(*args)
      warn_instead_of_syntax_error do
        execute_code(*args)
      end
    end

    def line_coverage(**options)
      Analyser::PerLine.new(self, **options).results
    end

    def char_cover(**options)
      Analyser::PerChar.new(self, **options).results
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

    def covered_source
      @covered_source ||= instrument_source
    end

    def instrument_source
      rewriter = Parser::Source::TreeRewriter.new(@buffer)
      covered_ast.each_node do |node|
        node.rewriting_rules.each do |range, rule|
          prefix, _node, suffix = rule.partition('%{node}')
          prefix = yield prefix, node, range.begin, :prefix if block_given? && !prefix.empty?
          suffix = yield suffix, node, range.end, :suffix if block_given? && !suffix.empty?
          rewriter.wrap(range, prefix, suffix)
        end
      end
      rewriter.process
    end

    def compile
      RubyVM::InstructionSequence.compile(covered_source, path.to_s, path.to_s)
    end

    def compile_or_warn
      warn_instead_of_syntax_error do
        compile
      end
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

    def warn_instead_of_syntax_error # &block
      yield
    rescue ::SyntaxError => e
      warn Tools.strip_heredoc(<<-MSG)
          DeepCover is getting confused with the file #{path} and it won't be instrumented.
          Please report this error and provide the source code around the following lines:
          #{e}
      MSG
      nil
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
