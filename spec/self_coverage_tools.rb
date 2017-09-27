require 'with_progress'

module DeepCover
  class CoveredCode
    def tracker_info
      [@nb, @tracker_count]
    end
  end

  class Coverage
    def tracker_sizes
      @covered_code.values.map(&:tracker_info).to_h
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
  end

  module Tools
    def dump_covered_code(source_path, dest_path = Dir.mktmpdir)
      coverage = Coverage.new(tracker_global: '$_sc')
      source_path = File.join(File.expand_path(source_path), '')
      dest_path = File.join(File.expand_path(dest_path), '')
      Dir.glob("#{source_path}**/*.rb").each.with_progress(title: 'Rewriting') do |path|
        covered_code = coverage.covered_code(path)
        new_path = Pathname(path.gsub(source_path, dest_path))
        new_path.dirname.mkpath
        new_path.write(covered_code.covered_source)
      end
      File.write("#{dest_path}coverage.deep_cover", Marshal.dump({
        version: DeepCover::VERSION,
        coverage: coverage,
      }))
      dest_path
    end

    def parse_covered_sources(version: raise, coverage: raise)
      puts "Warning: dump version mismatch: #{deep_cover}, currently #{DeepCover::VERSION}" unless version == DeepCover::VERSION
      coverage
    end

    def load_covered_sources(source_path)
      path = File.join(File.expand_path(source_path), 'coverage.deep_cover')
      puts "Loading", path
      parse_covered_sources Marshal.load(File.read(path))
    end
  end
end
