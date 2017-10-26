module DeepCover
  module Tools::BuiltinCoverage
    require 'coverage'

    def builtin_coverage(source, fn, lineno)
      fn = File.absolute_path(File.expand_path(fn))
      ::Coverage.start
      Tools.silence_warnings do
        execute_sample ->{ run_with_line_coverage(source, fn, lineno)}
      end
      unshift_coverage(::Coverage.result.fetch(fn), lineno)
    end

    if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
      # Executes the source as if it was in the specified file while
      # builtin coverage information is still captured
      def run_with_line_coverage(source, fn=nil, lineno=1)
        source = shift_source(source, lineno)
        Object.to_java.getRuntime.executeScript(source, fn)
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
      def run_with_line_coverage(source, fn=nil, lineno=1)
        source = shift_source(source, lineno)
        RubyVM::InstructionSequence.compile(source, fn).eval
      end
    end

    private

    def shift_source(source, lineno)
      "\n" * (lineno - 1) + source
    end

    def unshift_coverage(coverage, lineno)
      coverage[(lineno-1)..-1]
    end
  end
end
