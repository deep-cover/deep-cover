# frozen_string_literal: true

module DeepCover
  module Tools::ExecuteSample
    class ExceptionInSample < StandardError
    end

    # Returns true if the code would have continued, false if the rescue was triggered.
    def execute_sample(to_execute, source: nil)
      # Disable some annoying warning by ruby. We are testing edge cases, so warnings are to be expected.
      Tools.silence_warnings do
        if to_execute.is_a?(CoveredCode)
          to_execute.execute_code
        else
          to_execute.call
        end
      end
      true
    rescue StandardError => e
      # In our samples, a simple `raise` is expected and doesn't need to be rescued
      return false if e.is_a?(RuntimeError) && e.message.empty?

      source = to_execute.covered_source if to_execute.is_a?(CoveredCode)
      raise unless source

      inner_msg = Tools.indent_string("#{e.class.name}: #{e.message}", 4)
      source = Tools.indent_string(source, 4)
      msg = "Exception when executing the sample:\n#{inner_msg}\n*Code follows*\n#{source}"
      new_exc = ExceptionInSample.new(msg)
      new_exc.set_backtrace(e.backtrace)
      raise new_exc
    end
  end
end
