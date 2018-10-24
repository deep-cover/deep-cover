# frozen_string_literal: true

module DeepCover
  class CLI
    desc 'report [OPTIONS]', 'Generates report from coverage data that was gathered by previous commands'
    option '--output', desc: 'output folder', type: :string, default: DeepCover.config.output, aliases: '-o'
    option '--reporter', desc: 'reporter to use', type: :string, default: DeepCover.config.reporter
    option '--open', desc: 'open the output coverage', type: :boolean, default: CLI_DEFAULTS[:open]
    def report
      coverage = Coverage.load
      puts coverage.report(**processed_options)
    end
  end
end
