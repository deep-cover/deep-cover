module DeepCover
  module CLI
    class Debugger
      include Tools

      module ColorAST
        def fancy_type
          color = case
          when !executable?
            :faint
          when !was_executed?
            :red
          when flow_interrupt_count > 0
            :yellow
          else
            :green
          end
          Term::ANSIColor.send(color, super)
        end
      end

      attr_reader :options
      def initialize(source, filename: '(source)', lineno: 1, debug: false, **options)
        @source = source
        @filename = filename
        @lineno = lineno
        @debug = debug
        @options = options
      end

      def show
        execute
        if @debug
          show_line_coverage
          show_instrumented_code
          show_ast
        end
        show_char_coverage
        pry if @debug
        finish
      end

      def show_line_coverage
        output { "Line Coverage: Builtin | DeepCover | DeepCover Strict:\n" }
        begin
          builtin_line_coverage = builtin_coverage(@source, @filename, @lineno)
          our_line_coverage = our_coverage(@source, @filename, @lineno, **options)
          our_strict_line_coverage = our_coverage(@source, @filename, @lineno, allow_partial: false, **options)
          output do
            lines = format(builtin_line_coverage, our_line_coverage, our_strict_line_coverage, source: @source)
            number_lines(lines, lineno: @lineno)
          end
        rescue Exception => e
          output { "Can't run coverage: #{e.class.name}: #{e}\n#{e.backtrace.join("\n")}" }
          @failed = true
        end
      end

      def show_instrumented_code
        output { "\nInstrumented code:\n" }
        output { format_generated_code(covered_code) }
      end

      def show_ast
        output { "\nParsed code:\n" }
        Node.prepend ColorAST
        output { covered_code.covered_ast }
      end

      def show_char_coverage
        output { "\nChar coverage:\n" }

        output { format_char_cover(covered_code, show_whitespace: !!ENV['W'], **options) }
      end

      def pry
        a = covered_code.covered_ast
        b = a.children.first
        binding.pry
      end

      def finish
        exit(!@failed)
      end

      def covered_code
        @covered_code ||= CoveredCode.new(source: @source, path: @filename, lineno: @lineno)
      end

      def execute
        begin
          execute_sample(covered_code)
          # output { trace_counts }  # Keep for low-level debugging purposes
        rescue Exception => e
          output { "Can't `execute_sample`:#{e.class.name}: #{e}\n#{e.backtrace.join("\n")}" }
          @failed = true
        end
      end

      def trace_counts
        all = []
        TracePoint.new(:call) do |tr|
          if %i[flow_entry_count flow_completion_count execution_count].include? tr.method_id
            node = tr.self
            str = "#{node.type} #{(node.value if node.respond_to?(:value))} #{tr.method_id}"
            all << str unless all.last == str
          end
        end.enable { covered_code.freeze }
        all
      end

      def output
        puts yield
      end
    end
  end
end
