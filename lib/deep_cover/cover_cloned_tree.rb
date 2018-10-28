# frozen_string_literal: true

module DeepCover
  Tools.silence_warnings do
    require 'with_progress'
  end
  module Tools::CoverClonedTree
    def cover_cloned_tree(original_paths, original_root:, clone_root:)
      # Make sure the directories end with a '/' for safe replacing
      original_root = File.join(File.expand_path(original_root), '')
      clone_root = File.join(File.expand_path(clone_root), '')

      paths_with_bad_syntax = []
      original_paths, paths_not_in_root = original_paths.partition { |path| path.start_with?(original_root) }

      original_paths.each.with_progress(title: 'Rewriting') do |original_path|
        clone_path = Pathname(original_path.sub(original_root, clone_root))
        begin
          source = clone_path.read
          # We need to use the original_path so that the tracker_paths inserted in the files
          # during the instrumentation are for the original paths
          covered_code = DeepCover.coverage.covered_code(original_path, source: source)
        rescue Parser::SyntaxError
          paths_with_bad_syntax << original_path
          next
        end
        clone_path.dirname.mkpath
        clone_path.write(covered_code.covered_source)
      end

      unless paths_with_bad_syntax.empty?
        warn [
               "#{paths_with_bad_syntax.size} files could not be instrumented because of syntax errors:",
               *paths_with_bad_syntax.first(3),
               ('...' if paths_with_bad_syntax.size > 3),
             ].compact.join("\n")
      end

      unless paths_not_in_root.empty?
        warn [
               "#{paths_not_in_root.size} files could not be instrumented because they are not within the directory being cloned.",
               "(Consider configuring DeepCover's paths to to avoid those files being included)",
               *paths_not_in_root.first(5),
               ('...' if paths_not_in_root.size > 5),
             ].compact.join("\n")
      end

      nil
    end
  end

  Tools.extend Tools::CoverClonedTree
end
