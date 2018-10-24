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
    end
  end
end
