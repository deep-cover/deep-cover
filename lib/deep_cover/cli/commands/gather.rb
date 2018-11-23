# frozen_string_literal: true

module DeepCover
  class CLI
    # Stop parsing and treat everything as positional argument if
    # we encounter an unknown option or a positional argument.
    # `check_unknown_options!` (defined in cli.rb) happens first,
    # so we just stop on a positional argument.
    stop_on_unknown_option! :gather

    desc 'gather [OPTIONS] COMMAND TO RUN', 'Execute the command and gather the coverage data'
    def gather(*command_parts)
      if command_parts.empty?
        warn set_color('`gather` needs a command to run', :red)
        exit(1)
      end

      require 'yaml'
      env_var = {'DEEP_COVER' => 'gather',
                 'DEEP_COVER_OPTIONS' => YAML.dump(processed_options.slice(*DEFAULTS.keys)),
      }

      exit_code = Tools.run_command_or_exit(shell, env_var, *command_parts)
      exit(exit_code)
    end
  end
end
