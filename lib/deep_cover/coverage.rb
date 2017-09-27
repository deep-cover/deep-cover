require 'parser'
require 'parser/current'
require 'pry'
require 'pathname'
require_relative 'covered_code'

module DeepCover
  # A collection of CoveredCode
  class Coverage
    include Enumerable

    def initialize(**options)
      @covered_code = {}
      @options = options
    end

    def line_coverage(filename)
      covered_code(filename).line_coverage
    end

    def covered_code(path)
      raise 'path must be an absolute path' unless Pathname.new(path).absolute?
      @covered_code[path] ||= CoveredCode.new(path: path, **@options)
    end

    def each
      return to_enum unless block_given?
      @covered_code.each{|_path, covered_code| yield covered_code}
      self
    end

    def save(dest_path, basename = 'coverage.deep_cover')
      full_path = File.join(File.expand_path(dest_path), basename)
      File.write(full_path, Marshal.dump({
        version: DeepCover::VERSION,
        coverage: self,
      }))
      self
    end

    def report
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

    def self.load(dest_path, basename = 'coverage.deep_cover')
      full_path = File.join(File.expand_path(dest_path), basename)
      Marshal.load(File.read(full_path)).tap do |version: raise, coverage: raise|
        warn "Warning: dump version mismatch: #{deep_cover}, currently #{DeepCover::VERSION}" unless version == DeepCover::VERSION
        return coverage
      end
    end
  end
end
