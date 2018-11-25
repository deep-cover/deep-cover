# frozen_string_literal: true

require 'tempfile'

module DeepCover
  module Tools::BuiltinCoverage
    def builtin_coverage(source, filename, lineno)
      require 'coverage'
      filename = File.absolute_path(File.expand_path(filename))
      ::Coverage.start
      begin
        Tools.silence_warnings do
          execute_sample -> { filename = run_with_line_coverage(source, filename, lineno) }
        end
      ensure
        result = ::Coverage.result
      end
      unshift_coverage(result.fetch(filename), lineno)
    end

    def run_with_line_coverage(source, filename = '<code>', lineno = 1)
      source = shift_source(source, lineno)
      f = Tempfile.new(['ruby', '.rb'])
      f.write(source)
      f.close

      begin
        require f.path
      rescue StandardError => e
        tempfile_matcher = Regexp.new("\\A#{Regexp.escape(f.path)}(?=:\\d)")
        e.backtrace.each { |l| l.sub!(tempfile_matcher, filename) }
        raise
      end
      $LOADED_FEATURES.delete(f.path)
      f.path
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
