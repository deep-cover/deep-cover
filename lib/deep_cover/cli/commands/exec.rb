# frozen_string_literal: true

module DeepCover
  class CLI
    # Stop parsing and treat everything as positional argument if
    # we encounter an unknown option or a positional argument.
    # `check_unknown_options!` (defined in cli.rb) happens first,
    # so we just stop on a positional argument.
    stop_on_unknown_option! :exec

    desc 'exec [OPTIONS] [COMMAND TO RUN]', 'Execute the command with coverage activated'
    option '--output', desc: 'output folder', type: :string, default: DeepCover.config.output, aliases: '-o'
    option '--reporter', desc: 'reporter to use', type: :string, default: DeepCover.config.reporter
    option '--open', desc: 'open the output coverage', type: :boolean, default: CLI_DEFAULTS[:open]

    def exec(*command_parts)
      if command_parts.empty?
        command_parts = CLI_DEFAULTS[:command]
        puts "No command specified, using default of: #{command_parts.join(' ')}"
      end

      DeepCover.config.set(**processed_options.slice(*DEFAULTS.keys))

      require 'yaml'
      env_var = {'DEEP_COVER' => 'gather',
                 'DEEP_COVER_OPTIONS' => YAML.dump(DeepCover.config.to_hash_for_serialize),
      }

      DeepCover.delete_trackers
      exit_code = Tools.run_command_or_exit(shell, env_var, *command_parts)
      coverage = Coverage.load
      puts coverage.report(**processed_options)
      exit(exit_code)
    end
  end
end
