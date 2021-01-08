# frozen_string_literal: true

module DeepCover
  class CLI
    desc 'report [OPTIONS]', 'Generates report from coverage data that was gathered by previous commands'
    option '--output', desc: 'output folder', type: :string, default: DeepCover.config.output, aliases: '-o'
    option '--reporter', desc: 'reporter to use', type: :string, default: DeepCover.config.reporter
    option '--open', desc: 'open the output coverage', type: :boolean, default: CLI_DEFAULTS[:open]
    option '--minimum-coverage', desc: 'minimum coverage percent', type: :numeric, default: 0
    def report
      coverage = Coverage.load
      puts coverage.report(**processed_options)

      overall_coverage = coverage.analysis.overall
      minimum_coverage = processed_options.fetch('minimum-coverage'.to_sym, 0).to_f
      if overall_coverage < minimum_coverage
        puts "Overall coverage #{format('%.2f', overall_coverage)} is less than minimum #{format('%.2f', minimum_coverage)}"
        exit 1
      end
    end
  end
end
