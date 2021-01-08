# frozen_string_literal: true

require 'tmpdir'

module DeepCover
  class CLI
    desc 'clone [OPTIONS] [COMMAND TO RUN]', 'Gets the coverage using clone mode'
    option '--output', desc: 'output folder', type: :string, default: DeepCover.config.output, aliases: '-o'
    option '--reporter', desc: 'reporter to use', type: :string, default: DeepCover.config.reporter
    option '--open', desc: 'open the output coverage', type: :boolean, default: CLI_DEFAULTS[:open]
    option '--minimum-coverage', desc: 'minimum coverage percent', type: :numeric, default: 0

    def clone(*command_parts)
      if command_parts.empty?
        command_parts = CLI_DEFAULTS[:command]
        puts "No command specified, using default of: #{command_parts.join(' ')}"
      end

      require_relative '../../instrumented_clone_reporter'
      InstrumentedCloneReporter.new(**processed_options.merge(command: command_parts)).run
    end
  end
end
