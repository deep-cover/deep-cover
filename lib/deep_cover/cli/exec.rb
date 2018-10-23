# frozen_string_literal: true

module DeepCover
  class CLI
    # Stop parsing and treat everything as positional argument if
    # we encounter an unknown option or a positional argument.
    # `check_unknown_options!` (defined in cli.rb) happens first,
    # so we just stop on a positional argument.
    stop_on_unknown_option! :exec

    desc 'exec [OPTIONS] COMMAND TO RUN', 'Execute the command with coverage activated'
    option '--output', desc: 'output folder', type: :string, default: DeepCover.config.output, aliases: '-o'
    option '--reporter', desc: 'reporter to use', type: :string, default: DeepCover.config.reporter
    option '--open', desc: 'open the output coverage', type: :boolean, default: CLI_DEFAULTS[:open]

    def exec(*command_parts)
      if command_parts.empty?
        warn set_color('`exec` needs a command to run', :red)
        exit(1)
      end

      require 'yaml'
      env_var = {'DEEP_COVER' => 'exec',
                 'DEEP_COVER_OPTIONS' => YAML.dump(processed_options.transform_keys(&:to_sym).slice(*DEFAULTS.keys)),
      }

      # Clear inspiration from Bundler's kernel_exec
      # https://github.com/bundler/bundler/blob/d44d803357506895555ff97f73e60d593820a0de/lib/bundler/cli/exec.rb#L50
      begin
        Kernel.exec(env_var, *command_parts)
      rescue Errno::EACCES, Errno::ENOEXEC
        warn set_color("not executable: #{command_parts.first}", :red)
        exit 126 # Default exit code for that
      rescue Errno::ENOENT
        warn set_color("command not found: #{command_parts.first}", :red)
        exit 127 # Default exit code for that
      end
    end
  end
end
