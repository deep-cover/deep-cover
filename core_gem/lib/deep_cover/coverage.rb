# frozen_string_literal: true

module DeepCover
  bootstrap

  require_relative_dir 'coverage'

  # A collection of CoveredCode
  class Coverage
    include Enumerable

    attr_reader :tracker_storage_per_path

    def initialize
      @covered_code_index = {}
      @tracker_storage_per_path = TrackerStoragePerPath.new(TrackerBucket[tracker_global])
    end

    def covered_codes
      each.to_a
    end

    def line_coverage(filename, **options)
      covered_code(filename).line_coverage(**options)
    end

    def covered_code?(path)
      @covered_code_index.include?(path)
    end

    def covered_code(path, **options)
      raise 'path must be an absolute path' unless Pathname.new(path).absolute?
      @covered_code_index[path] ||= CoveredCode.new(path: path,
                                                    tracker_storage: @tracker_storage_per_path[path],
                                                    tracker_global: DeepCover.config.tracker_global,
                                                    **options)
    end

    def covered_code_or_warn(path, **options)
      covered_code(path, **options)
    rescue Parser::SyntaxError => e
      if e.message =~ /contains escape sequences incompatible with UTF-8/
        warn "Can't cover #{path} because of incompatible encoding (see issue #9)"
      else
        warn "The file #{path} can't be instrumented"
      end
      nil
    end


    def each
      return to_enum unless block_given?
      @tracker_storage_per_path.each_key do |path|
        begin
          cov_code = covered_code(path)
        rescue Parser::SyntaxError
          next
        end
        yield cov_code
      end
      self
    end

    def report(reporter: DEFAULTS[:reporter], **options)
      case reporter.to_sym
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
      Persistence.new(dest_path, dirname).save_trackers(@tracker_storage_per_path.tracker_hits_per_path)
      self
    end

    def tracker_global
      DeepCover.config.tracker_global
    end

    def analysis(**options)
      Analysis.new(covered_codes, **options)
    end

    private

    def marshal_dump
      {tracker_storage_per_path: @tracker_storage_per_path}
    end

    def marshal_load(tracker_storage_per_path:)
      initialize
      @tracker_storage_per_path = tracker_storage_per_path
    end
  end
end
