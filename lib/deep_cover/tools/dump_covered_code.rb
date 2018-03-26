# frozen_string_literal: true

module DeepCover
  silence_warnings do
    require 'with_progress'
  end
  module Tools::DumpCoveredCode
    def dump_covered_code(source_path, coverage:, dest_path: Dir.mktmpdir, root_path: source_path)
      source_path = File.join(File.expand_path(source_path), '')
      dest_path = File.join(File.expand_path(dest_path), '')
      root_path = Pathname.new(root_path)
      skipped = []
      file_paths = Dir.glob("#{source_path}**/*.rb").select { |p| File.file?(p) }
      file_paths.each.with_progress(title: 'Rewriting') do |path|
        new_path = Pathname(path.gsub(source_path, dest_path))
        begin
          covered_code = coverage.covered_code(path)
        rescue Parser::SyntaxError
          skipped << path
          next
        end
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
      dest_path
    end
  end
end
