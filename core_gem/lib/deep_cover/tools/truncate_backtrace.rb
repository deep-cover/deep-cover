# frozen_string_literal: true

module DeepCover
  module Tools::TruncateBacktrace
    def truncate_backtrace(backtrace, extra_context: 10)
      backtrace = backtrace.backtrace if backtrace.is_a?(Exception)
      trace_lines = backtrace.uniq

      keep_from_begin = 0
      keep_from_end = backtrace.size - 1

      trace_lines.each do |line|
        from_begin = backtrace.index(line)
        from_end = backtrace.rindex(line)
        if from_begin <= backtrace.size - 1 - from_end
          keep_from_begin = [keep_from_begin, from_begin].max
        else
          keep_from_end = [keep_from_end, from_end].min
        end
      end

      keep_from_begin += extra_context
      keep_from_end -= extra_context

      return backtrace if keep_from_begin + 5 >= keep_from_end

      result = backtrace[0..keep_from_begin]
      result << "... #{keep_from_end - keep_from_begin - 1} levels..."
      result.concat backtrace[keep_from_end..-1]
    end
  end
end
