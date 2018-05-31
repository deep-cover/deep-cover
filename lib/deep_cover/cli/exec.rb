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
        require 'yaml'
        require_relative '../backports'
        env_var = {'DEEP_COVER' => 't',
                   'DEEP_COVER_OPTIONS' => YAML.dump(@options.slice(*DEFAULTS.keys))}

        system(env_var, *@argv)
      end
    end
  end
end
