# frozen_string_literal: true

require 'tmpdir'

module DeepCover
  class CLI
    desc 'clone [OPTIONS] [PATH]', 'Gets the coverage using clone mode'
    option '--output', desc: 'output folder', type: :string, default: DeepCover.config.output, aliases: '-o'
    option '--reporter', desc: 'reporter to use', type: :string, default: DeepCover.config.reporter
    option '--open', desc: 'open the output coverage', type: :boolean, default: CLI_DEFAULTS[:open]

    option '--command', desc: 'command to run tests', type: :string, default: CLI_DEFAULTS[:command], aliases: '-c'
    option '--bundle', desc: 'run bundle before the tests', type: :boolean, default: CLI_DEFAULTS[:bundle]
    option '--process', desc: 'turn off to only redo the reporting', type: :boolean, default: CLI_DEFAULTS[:process]

    def clone(path = '.')
      require_relative '../../instrumented_clone_reporter'
      InstrumentedCloneReporter.new(path, **processed_options.transform_keys(&:to_sym)).run
    end
  end
end
