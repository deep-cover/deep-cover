# frozen_string_literal: true

module DeepCover
  bootstrap

  require_relative_dir 'coverage'

  # A collection of CoveredCode
  class Coverage
    include Enumerable

    attr_reader :tracker_storage_per_path

    def initialize(**options)
      @covered_code_index = {}
      @options = options
      @tracker_storage_per_path = TrackerStoragePerPath.new(TrackerBucket[tracker_global])
    end

    def covered_codes
      @covered_code_index.values
    end

    def line_coverage(filename, **options)
      covered_code(filename).line_coverage(**options)
    end

    def covered_code(path, **options)
      raise 'path must be an absolute path' unless Pathname.new(path).absolute?
      @covered_code_index[path] ||= CoveredCode.new(path: path,
                                                    tracker_storage: @tracker_storage_per_path[path],
                                                    **options,
                                                    **@options)
    end

    def each
      return to_enum unless block_given?
      @covered_code_index.each_value { |covered_code| yield covered_code }
      self
    end

    def report(**options)
      case (reporter = options.fetch(:reporter, DEFAULTS[:reporter]).to_sym)
      when :html
        msg = if (output = options.fetch(:output, DEFAULTS[:output]))
                Reporter::HTML.report(self, **options)
                "HTML generated: open #{output}/index.html"
              else
                'No HTML generated'
              end
        Reporter::Text.report(self, **options) + "\n\n" + msg
      when :istanbul
        if Reporter::Istanbul.available?
          Reporter::Istanbul.report(self, **options)
        else
          warn 'nyc not available. Please install `nyc` using `yarn global add nyc` or `npm i nyc -g`'
        end
      when :text
        Reporter::Text.report(self, **options)
      else
        raise ArgumentError, "Unknown reporter: #{reporter}"
      end
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
      @options.fetch(:tracker_global, DEFAULTS[:tracker_global])
    end

    def analysis(**options)
      Analysis.new(covered_codes, options)
    end
  end
end
