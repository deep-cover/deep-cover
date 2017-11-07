module DeepCover
  require 'bundler/setup'
  require 'slop'
  require 'deep_cover'
  require_relative_dir '.'

  module CLI
    module DeepCover
      extend self

      def show_version
        puts "deep-cover v#{DeepCover::VERSION}; parser v#{Parser::Version}"
      end

      def show_help
        puts menu
      end

      class Parser < Struct.new(:delegate)
        def method_missing(method, *args, &block)
          options = args.last
          if options.is_a?(Hash) && options.has_key?(:default)
            args[-2] += " [#{options[:default]}]"
          end
          delegate.public_send(method, *args, &block)
        end
      end

      def parse
        Slop.parse do |o|
          yield Parser.new(o)
        end
      end

      def menu
        @menu ||= parse do |o|
          o.banner = "usage: deep-cover [options] [path/to/app/or/gem]"
          o.separator ''
          o.string '-o', '--output', 'output folder', default: './coverage'
          o.string '-c', '--command', 'command to run tests', default: 'bundle exec rake'
          o.bool '--bundle', 'run bundle before the tests', default: true
          o.bool '--process', 'turn off to only redo the reporting', default: true
          o.separator 'Coverage options'
          @ignore_uncovered_map = Analyser.optionally_covered.map do |option|
            default = Config::DEFAULTS[:ignore_uncovered].include?(option)
            o.bool "--ignore-#{Tools.dasherize(option)}", "", default: default
            [:"ignore_#{option}", option]
          end.to_h
          o.separator ''
          o.separator 'For testing purposes:'
          o.string '-e', '--expression', 'test ruby expression instead of a covering a path'
          o.bool '-d', '--debug', 'enter debugging after cover'

          o.separator ''
          o.separator 'Other available commands:'
          o.on('--version', 'print the version') { version; exit }
          o.on('-h', '--help') { help; exit }
        end
      end

      def convert_options(options)
        iu = options[:ignore_uncovered] = []
        @ignore_uncovered_map.each do |cli_option, option|
          iu << option if options.delete(cli_option)
        end
        options
      end

      def go
        options = convert_options(menu.to_h)
        if options[:expression]
          Debugger.new(options[:expression], **options).show
        elsif (path = menu.arguments.first)
          InstrumentedCloneReporter.new(path, **options).run
        else
          show_help
        end
      end
    end
  end
end
