# frozen_string_literal: true

module DeepCover
  class CLI
    # Add some top-level aliases for this command
    # So it's possible to do `deep-cover -v` or `deep-cover --version`
    map %w(-v --version) => :version

    desc 'version', "Print deep-cover's version"
    def version
      require 'deep_cover/version'
      puts "deep-cover version #{DeepCover::VERSION}"
    end
  end
end
