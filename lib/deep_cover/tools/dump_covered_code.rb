require 'with_progress'

module DeepCover
  module Tools::DumpCoveredCode
    def dump_covered_code(source_path, dest_path = Dir.mktmpdir)
      coverage = Coverage.new(tracker_global: '$_sc')
      source_path = File.join(File.expand_path(source_path), '')
      dest_path = File.join(File.expand_path(dest_path), '')
      skipped = []
      Dir.glob("#{source_path}**/*.rb").each.with_progress(title: 'Rewriting') do |path|
        begin
          covered_code = coverage.covered_code(path)
        rescue Parser::SyntaxError
          skipped << path
          next
        end
        new_path = Pathname(path.gsub(source_path, dest_path))
        new_path.dirname.mkpath
        new_path.write(covered_code.covered_source)
      end
      unless skipped.empty?
        warn [
          "#{skipped.size} files could not be instrumented because of syntax errors:",
          *skipped.first(3),
          ('...' if skipped.size > 3),
        ].compact.join("\n")
      end
      coverage.save(dest_path)
      dest_path
    end
  end
end
