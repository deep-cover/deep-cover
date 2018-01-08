# frozen_string_literal: true

module DeepCover
  module CLI
    class Exec
      class Option
        def keep_file_descriptors?
        end
      end

      def initialize(argv, **options)
        @argv = argv
        @options = options
      end

      def run
        require 'bundler'
        require 'bundler/cli'
        require 'bundler/cli/exec'
        require 'yaml'
        require_relative '../backports'
        ENV['DEEP_COVER'] = 't'
        ENV['DEEP_COVER_OPTIONS'] = YAML.dump(@options.slice(*DEFAULTS.keys))
        Bundler::CLI::Exec.new(Option.new, @argv).run
      end
    end
  end
end
