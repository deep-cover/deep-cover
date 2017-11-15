# frozen_string_literal: true

module DeepCover
  require 'parser'
  silence_warnings do
    require 'parser/current'
  end
  require_relative 'covered_code'
  require 'securerandom'

  # A collection of CoveredCode
  class Coverage
    include Enumerable

    def initialize(**options)
      @covered_codes = {}
      @options = options
    end

    def covered_codes
      @covered_codes.dup
    end

    def reset
      @covered_codes = {}
    end

    def line_coverage(filename, **options)
      covered_code(filename).line_coverage(**options)
    end

    def covered_code(path, **options)
      raise 'path must be an absolute path' unless Pathname.new(path).absolute?
      @covered_codes[path] ||= CoveredCode.new(path: path, **options, **@options)
    end

    def each
      return to_enum unless block_given?
      @covered_codes.each_value { |covered_code| yield covered_code }
      self
    end

    def to_istanbul(**options)
      map do |covered_code|
        next {} unless covered_code.has_executed?
        covered_code.to_istanbul(**options)
      end.inject(:merge)
    end

    def output_istanbul(dir: '.', name: '.nyc_output', **options)
      path = Pathname.new(dir).expand_path.join(name)
      path.mkpath
      path.each_child(&:delete)
      path.join('deep_cover.json').write(JSON.pretty_generate(to_istanbul(**options)))
      path
    end

    def report_istanbul(output: nil, **options)
      dir = output_istanbul(**options).dirname
      unless [nil, '', 'false'].include? output
        output = File.expand_path(output)
        html = "--reporter=html --report-dir='#{output}'"
        if options[:open]
          html += " && open '#{output}/index.html'"
        else
          msg = "\nHTML coverage written to: '#{output}/index.html'"
        end
      end
      `cd #{dir} && nyc report --reporter=text #{html}` + msg.to_s
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

    def report(**options)
      if Reporter::Istanbul.available?
        report_istanbul(**options)
      else
        warn 'nyc not available. Please install `nyc` using `yarn global add nyc` or `npm i nyc -g`'
        basic_report
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
      @options.fetch(:tracker_global, CoveredCode::DEFAULT_TRACKER_GLOBAL)
    end

    class Persistence
      # rubocop:disable Security/MarshalLoad
      BASENAME = 'coverage.dc'
      TRACKER_TEMPLATE = 'trackers%{unique}.dct'

      attr_reader :dir_path
      def initialize(dest_path, dirname)
        @dir_path = Pathname(dest_path).join(dirname).expand_path
      end

      def load(with_trackers: true)
        saved?
        load_trackers if with_trackers
        load_coverage
      end

      def save(coverage)
        create_if_needed
        delete_trackers
        save_coverage(coverage)
      end

      def save_trackers(global)
        saved?
        trackers = eval(global) # rubocop:disable Security/Eval
        # Some testing involves more than one process, some of which don't run any of our covered code.
        # Don't save anything if that's the case
        return if trackers.nil?
        basename = format(TRACKER_TEMPLATE, unique: SecureRandom.urlsafe_base64)
        dir_path.join(basename).binwrite(Marshal.dump(
                                             version: DeepCover::VERSION,
                                             global: global,
                                             trackers: trackers,
        ))
      end

      def saved?
        raise "Can't find folder '#{dir_path}'" unless dir_path.exist?
        self
      end

      private

      def create_if_needed
        dir_path.mkpath
      end

      def save_coverage(coverage)
        dir_path.join(BASENAME).binwrite(Marshal.dump(
                                             version: DeepCover::VERSION,
                                             coverage: coverage,
        ))
      end

      def load_coverage
        Marshal.load(dir_path.join(BASENAME).binread).tap do |version: raise, coverage: raise|
          raise "dump version mismatch: #{version}, currently #{DeepCover::VERSION}" unless version == DeepCover::VERSION
          return coverage
        end
      end

      def load_trackers
        tracker_files.each do |full_path|
          Marshal.load(full_path.binread).tap do |version: raise, global: raise, trackers: raise|
            raise "dump version mismatch: #{version}, currently #{DeepCover::VERSION}" unless version == DeepCover::VERSION
            merge_trackers(eval("#{global} ||= {}"), trackers) # rubocop:disable Security/Eval
          end
        end
      end

      def merge_trackers(hash, to_merge)
        hash.merge!(to_merge) do |_key, current, to_add|
          unless current.empty? || current.size == to_add.size
            warn "Merging trackers of different sizes: #{current.size} vs #{to_add.size}"
          end
          to_add.zip(current).map { |a, b| a + b }
        end
      end

      def tracker_files
        basename = format(TRACKER_TEMPLATE, unique: '*')
        Pathname.glob(dir_path.join(basename))
      end

      def delete_trackers
        tracker_files.each(&:delete)
      end
    end
  end
end
