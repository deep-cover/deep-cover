# frozen_string_literal: true

module DeepCover
  class ProblemWithDiagnostic < StandardError
    attr_reader :covered_code, :line_range, :original_exception

    def initialize(covered_code, line_range, original_exception=nil)
      @covered_code = covered_code
      if line_range.is_a?(Parser::Source::Range)
        @line_range = line_range.line..line_range.last_line
      else
        @line_range = line_range
      end
      @original_exception = original_exception
    end

    def message
      msg = []
      msg << 'You found a problem with DeepCover!'
      msg << 'Please open an issue at https://github.com/deep-cover/deep-cover/issues'
      msg << 'and include the following diagnostic information:'
      extra = begin
        diagnostic_information_lines.map{|line| "| #{line}"}
      rescue ProblemWithDiagnostic
        ["Oh no! We're in deep trouble!!!"]
      rescue Exception => e
        ["Oh no! Even diagnostics are failing: #{e}\n#{e.backtrace}"]
      end
      msg.concat(extra)
      msg.join("\n")
    end

    def diagnostic_information_lines
      lines = []
      lines << "Source file: #{covered_code.path}"
      lines << "Line numbers: #{line_range}"
      lines << 'Source lines around location:'
      lines.concat source_lines.map{|line| "   #{line}" }
      if original_exception
        lines << 'Original exception:'
        lines << "  #{original_exception.class.name}: #{original_exception.message}"
        backtrace = Tools.truncate_backtrace(original_exception)
        lines.concat backtrace.map{|line| "    #{line}"}
      end
      lines
    end

    def source_lines(nb_context_line: 7)
      first_index = line_range.begin - nb_context_line - buffer.first_line
      first_index = 0 if first_index < 0
      last_index = line_range.end + nb_context_line - buffer.first_line
      last_index = 0 if last_index < 0

      lines = buffer.source_lines[first_index..last_index]

      Tools.number_lines(lines, lineno: buffer.first_line, bad_linenos: line_range.to_a)
    end

    def buffer
      covered_code.buffer
    end
  end
end
