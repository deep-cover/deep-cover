# frozen_string_literal: true

module DeepCover
  bootstrap
  load_parser

  class CoveredCode
    attr_accessor :buffer, :local_var, :path

    def initialize(
      path: nil,
      source: nil,
      lineno: 1,
      local_var: '_temp',
      tracker_hits: nil
    )
      raise 'Must provide either path or source' unless path || source

      @path = path &&= Pathname(path)
      @buffer = Parser::Source::Buffer.new('', lineno)
      @buffer.source = source || path.read
      @index = nil # Set in #instrument_source
      @local_var = local_var
      @covered_source = nil # Set in #covered_source
      @tracker_hits = tracker_hits # Loaded from global in #tracker_hits, or when received right away when loading data
      @nb_allocated_trackers = 0
      # We parse the code now so that problems happen early
      covered_ast
      @tracker_hits = Array.new(@nb_allocated_trackers, 0) if @tracker_hits == :zeroes
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

    def setup_tracking_source
      src = "(#{DeepCover.config.tracker_global}||={})[#{@index}]||=Array.new(#{@nb_allocated_trackers},0)"
      src += ";(#{DeepCover.config.tracker_global}_p||={})[#{@index}]=#{path.to_s.inspect}" if path
      src
    end

    def increment_tracker_source(tracker_id)
      "#{DeepCover.config.tracker_global}[#{@index}][#{tracker_id}]+=1"
    end

    def allocate_trackers(nb_needed)
      return @nb_allocated_trackers...@nb_allocated_trackers if nb_needed == 0
      prev = @nb_allocated_trackers
      @nb_allocated_trackers += nb_needed
      prev...@nb_allocated_trackers
    end

    def tracker_hits
      return @tracker_hits if @tracker_hits
      global_trackers = DeepCover::GlobalVariables.trackers[@index]

      return unless global_trackers

      if global_trackers.size != @nb_allocated_trackers
        raise "Cannot sync path: #{path.inspect}, global[#{@index}] is of size #{global_trackers.size} instead of expected #{@nb_allocated_trackers}"
      end

      @tracker_hits = global_trackers
    end

    def covered_source
      @covered_source ||= instrument_source
    end

    def instrument_source
      @index ||= self.class.next_global_index

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
        tracker_hits
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

    def self.next_global_index
      @last_allocated_global_index ||= -1
      @last_allocated_global_index += 1
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
