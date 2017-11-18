# frozen_string_literal: true

module DeepCover
  # A collection of CoveredCode
  class Coverage
    include Enumerable

    def initialize(**options)
      @covered_code_index = {}
      @options = options
    end

    def covered_codes
      @covered_code_index.values
    end

    def reset
      @covered_code_index = {}
    end

    def line_coverage(filename, **options)
      covered_code(filename).line_coverage(**options)
    end

    def covered_code(path, **options)
      raise 'path must be an absolute path' unless Pathname.new(path).absolute?
      @covered_code_index[path] ||= CoveredCode.new(path: path, **options, **@options)
    end

    def each
      return to_enum unless block_given?
      @covered_code_index.each_value { |covered_code| yield covered_code }
      self
    end

    def report(**options)
      if Reporter::Istanbul.available?
        report_istanbul(**options)
      else
        warn 'nyc not available. Please install `nyc` using `yarn global add nyc` or `npm i nyc -g`'
        basic_report
      end
    end

    def basic_report
      missing = map do |covered_code|
        if covered_code.has_executed?
          missed = covered_code.line_coverage.each_with_index.map do |line_cov, line_index|
            line_index + 1 if line_cov == 0
          end.compact
        else
          missed = ['all']
        end
        [covered_code.buffer.name, missed] unless missed.empty?
      end.compact.to_h
      missing.map do |path, lines|
        "#{File.basename(path)}: #{lines.join(', ')}"
      end.join("\n")
    end

    def self.load(dest_path, dirname = 'deep_cover', with_trackers: true)
      Persistence.new(dest_path, dirname).load(with_trackers: with_trackers)
    end

    def self.saved?(dest_path, dirname = 'deep_cover')
      Persistence.new(dest_path, dirname).saved?
    end

    def save(dest_path, dirname = 'deep_cover')
      Persistence.new(dest_path, dirname).save(self)
      self
    end

    def save_trackers(dest_path, dirname = 'deep_cover')
      Persistence.new(dest_path, dirname).save_trackers(tracker_global)
      self
    end

    def tracker_global
      @options.fetch(:tracker_global, CoveredCode::DEFAULT_TRACKER_GLOBAL)
    end
  end
end
