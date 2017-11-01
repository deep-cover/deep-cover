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
        puts options
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

      def options
        @options ||= parse do |o|
          o.banner = "usage: deep-cover [options] [path/to/app/or/gem]"
          o.separator ''
          o.string '-o', '--output', 'output folder', default: './coverage'
          o.string '-c', '--command', 'command to run tests', default: 'rake'
          o.bool '--bundle', 'run bundle before the tests', default: true

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

      def go
        if options[:expression]
          Debugger.new(options[:expression], pry: options[:debug]).show
        elsif (path = options.arguments.first)
          InstrumentedCloneReporter.new(path, **options).run
        else
          show_help
        end
      end
    end
  end
end
