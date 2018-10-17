# frozen_string_literal: true

module DeepCover
  bootstrap

  require_relative_dir 'coverage'

  # A collection of CoveredCode
  class Coverage
    include Enumerable

    def initialize
      @covered_code_index = {}
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
      @covered_code_index.each_key do |path|
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

    def self.load(cache_directory = DeepCover.config.cache_directory)
      tracker_hits_per_path = Persistence.new(cache_directory).load_trackers
      coverage = Coverage.new

      tracker_hits_per_path.each do |path, tracker_hits|
        coverage.covered_code(path, tracker_hits: tracker_hits)
      end

      coverage
    end

    def save_trackers
      tracker_hits_per_path = covered_code_index.map do |path, covered_code|
        [path, covered_code.tracker_hits]
      end
      tracker_hits_per_path = tracker_hits_per_path.to_h

      DeepCover.persistence.save_trackers(tracker_hits_per_path)
      self
    end

    def analysis(**options)
      Analysis.new(covered_codes, **options)
    end
  end
end
