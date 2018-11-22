# frozen_string_literal: true

module DeepCover
  module Tools::BuiltinCoverage
    def builtin_coverage(source, filename, lineno)
      require 'coverage'
      filename = File.absolute_path(File.expand_path(filename))
      ::Coverage.start
      begin
        Tools.silence_warnings do
          execute_sample -> { run_with_line_coverage(source, filename, lineno) }
        end
      ensure
        result = ::Coverage.result
      end
      unshift_coverage(result.fetch(filename), lineno)
    end

    if RUBY_PLATFORM == 'java'
      # Executes the source as if it was in the specified file while
      # builtin coverage information is still captured
      def run_with_line_coverage(source, filename = nil, lineno = 1)
        source = shift_source(source, lineno)
        Object.to_java.getRuntime.executeScript(source, filename)
      end
    else
      # In ruby 2.0 and 2.1, using 2, 3 or 4 as lineno with RubyVM::InstructionSequence.compile
      # will cause the coverage result to be truncated.
      # 1: [1,2,nil,1]
      # 2: [nil,1,2,nil]
      # 3: [nil,nil,1,2]
      # 4: [nil,nil,nil,1]
      # 5: [nil,nil,nil,nil,1,2,nil,1]
      # Using 1 and 5 or more do not seem to show this issue.
      # The workaround is to create the fake lines manually and always use the default lineno

      # Executes the source as if it was in the specified file while
      # builtin coverage information is still captured
      def run_with_line_coverage(source, filename = nil, lineno = 1)
        source = shift_source(source, lineno)
        RubyVM::InstructionSequence.compile(source, filename).eval
      end
    end

    private

    def shift_source(source, lineno)
      "\n" * (lineno - 1) + source
    end

    def unshift_coverage(coverage, lineno)
      coverage[(lineno - 1)..-1]
    end
  end
end
