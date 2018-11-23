# frozen_string_literal: true

module DeepCover
  class CLI
    module Tools
      # Extracts the commands for the help by name, in same order as the names.
      # This make handling the output of printable_commands more easily.
      # Returns the matching and the remaining commands.
      def self.extract_commands_for_help(commands, *names)
        matching = names.map do |name|
          commands.detect { |usage, desc| usage.start_with?("deep-cover #{name}") }
        end
        remains = commands - matching
        [matching, remains]
      end

      # Basically does the same as Kernel.system, but:
      # * exits with an error message when unable to start the command
      # * returns the error code instead of just true/false
      def self.run_command_or_exit(shell, env_var, *command_parts)
        # Clear inspiration from Bundler's kernel_exec
        # https://github.com/bundler/bundler/blob/d44d803357506895555ff97f73e60d593820a0de/lib/bundler/cli/exec.rb#L50
        begin
          pid = Kernel.spawn(env_var, *command_parts)
        rescue Errno::EACCES, Errno::ENOEXEC
          warn shell.set_color("not executable: #{command_parts.first}", :red)
          exit 126 # Default exit code for that
        rescue Errno::ENOENT
          warn shell.set_color("command not found: #{command_parts.first}", :red)
          exit 127 # Default exit code for that
        end
        Process.wait pid
        $?.exitstatus
      end
    end
  end
end
