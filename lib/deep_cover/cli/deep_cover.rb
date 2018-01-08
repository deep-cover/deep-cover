# frozen_string_literal: true

module DeepCover
  require 'bundler/setup'
  require 'slop'
  require_relative '../basics'

  module CLI
  end
  module CLI::DeepCover
    extend self

    def show_version
      require_relative '../version'
      require 'parser'
      puts "deep-cover v#{DeepCover::VERSION}; parser v#{Parser::VERSION}"
    end

    def show_help
      puts menu
    end

    class OptionParser < Struct.new(:delegate)
      def method_missing(method, *args, &block) # rubocop:disable Style/MethodMissing
        options = args.last
        if options.is_a?(Hash) && options.has_key?(:default)
          args[-2] += " [#{options[:default]}]"
        end
        delegate.public_send(method, *args, &block)
      end
    end

    def parse
      Slop.parse do |o|
        yield OptionParser.new(o)
      end
    end

    def menu
      @menu ||= parse do |o|
        o.banner = ['usage: deep-cover [options] exec <command ...>',
                    '   or  deep-cover [options] [path/to/app/or/gem]',
                   ].join("\n")
        o.separator ''
        o.string '-o', '--output', 'output folder', default: DEFAULTS[:output]
        o.string '--reporter', 'reporter', default: DEFAULTS[:reporter]
        o.bool '--open', 'open the output coverage', default: CLI_DEFAULTS[:open]

        o.separator 'Coverage options'
        @ignore_uncovered_map = OPTIONALLY_COVERED.map do |option|
          default = DEFAULTS[:ignore_uncovered].include?(option)
          o.bool "--ignore-#{dasherize(option)}", '', default: default
          [:"ignore_#{option}", option]
        end.to_h

        o.separator '\nWhen not using ’exec’:'
        o.string '-c', '--command', 'command to run tests', default: CLI_DEFAULTS[:command]
        o.bool '--bundle', 'run bundle before the tests', default: CLI_DEFAULTS[:bundle]
        o.bool '--process', 'turn off to only redo the reporting', default: CLI_DEFAULTS[:process]

        o.separator "\nFor testing purposes:"
        o.bool '--profile', 'use profiler' unless RUBY_PLATFORM == 'java'
        o.string '-e', '--expression', 'test ruby expression instead of a covering a path'
        o.bool '-d', '--debug', 'enter debugging after cover'

        o.separator "\nOther available commands:"
        o.on('--version', 'print the version') do
          show_version
          exit
        end
        o.boolean('-h', '--help')
      end
    end

    def convert_options(options)
      iu = options[:ignore_uncovered] = []
      @ignore_uncovered_map.each do |cli_option, option|
        iu << option if options.delete(cli_option)
      end
      options[:output] = false if ['false', 'f', ''].include?(options[:output])
      options
    end

    def go
      options = convert_options(menu.to_h)
      first, *rest = menu.arguments
      if options[:help]
        show_help
      elsif options[:expression]
        require_relative 'debugger'
        CLI::Debugger.new(options[:expression], **options).show
      elsif first == 'exec'
        require_relative 'exec'
        CLI::Exec.new(rest, **options).run
      else
        require_relative 'instrumented_clone_reporter'
        path = first || '.'
        CLI::InstrumentedCloneReporter.new(path, **options).run
      end
    end

    private

    # Poor man's dasherize. 'an_example' => 'an-example'
    def dasherize(string)
      string.to_s.tr('_', '-')
    end
  end
end
