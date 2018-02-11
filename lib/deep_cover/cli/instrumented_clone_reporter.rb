# frozen_string_literal: true

require 'tmpdir'

module DeepCover
  require_relative '../../deep_cover'
  bootstrap

  module CLI
    class InstrumentedCloneReporter
      include Tools
      # matches regular files, .files, ..files, but not '.' or '..'
      GLOB_ALL_CONTENT = '{,.[^.],..?}*'

      def initialize(source_path, **options)
        @options = CLI_DEFAULTS.merge(options)
        @root_path = @source_path = Pathname.new(source_path).expand_path
        unless @root_path.join('Gemfile').exist?
          # E.g. rails/activesupport
          @root_path = @root_path.dirname
          raise "Can't find Gemfile" unless @root_path.join('Gemfile').exist?
        end
        @dest_root = Pathname('~/test_deep_cover').expand_path
        @dest_root = Pathname.new(Dir.mktmpdir('deep_cover_test')) unless @dest_root.exist?

        gem_relative_path = @source_path.relative_path_from(@root_path)
        @main_path = @dest_root.join(gem_relative_path)
        singleton_class.include self.class.const_get(Tools.camelize(style))
      end

      def clear
        FileUtils.rm_rf(Dir.glob("#{@dest_root}/#{GLOB_ALL_CONTENT}"))
      end

      def copy
        return true if @copied
        puts 'Cloning...'
        FileUtils.cp_r(Dir.glob("#{@root_path}/#{GLOB_ALL_CONTENT}"), @dest_root)
        @copied = true
      end

      def patch_ruby_file(ruby_file)
        content = ruby_file.read
        # Insert our code after leading comments:
        content.sub!(/^(#.*\n+)*/) { |header| "#{header}require 'deep_cover/auto_run';DeepCover::AutoRun.run! '#{@dest_root}';" }
        ruby_file.write(content)
      end

      def style
        if @source_path.join('config/environments/test.rb').exist?
          :rails
        elsif @source_path.join('lib').exist?
          :single_gem
        else # Rails style
          :gem_collection
        end
      end

      # Style specific functionality
      module Gem
        def each_main_ruby_files(&block)
          each_gem_path do |dest_path|
            main = dest_path.join('lib/*.rb')
            Pathname.glob(main).select(&:file?).each(&block)
          end
        end

        def each_dir_to_cover
          each_gem_path do |dest_path|
            yield dest_path.join('lib')
          end
        end
      end

      module SingleGem
        include Gem
        def each_gem_path
          yield @main_path
        end
      end

      module GemCollection
        include Gem
        def each_gem_path
          Pathname.glob(@main_path.join('*/lib')).each { |p| yield p.dirname }
        end
      end

      module Rails
        def each_main_ruby_files
          yield @main_path.join('config/environments/test.rb')
        end

        def each_dir_to_cover
          yield @main_path.join('app')
          yield @main_path.join('lib')
        end
      end

      # Back to global functionality
      def patch_main_ruby_files
        each_main_ruby_files do |main|
          puts "Patching #{main}"
          patch_ruby_file(main)
        end
      end

      def patch_gemfile
        gemfile = @dest_root.join('Gemfile')
        deps = Bundler::Definition.build(gemfile, nil, nil).dependencies

        return if deps.find { |e| e.name == 'deep-cover' }

        content = File.read(gemfile)
        puts "Patching Gemfile #{gemfile}"
        File.write(gemfile, [
                              '# This file was modified by DeepCover',
                              content,
                              "gem 'deep-cover', path: '#{File.expand_path(__dir__ + '/../../../')}'",
                              '',
                            ].join("\n"))
      end

      def patch_rubocop
        path = @dest_root.join('.rubocop.yml')
        return unless path.exist?
        puts 'Patching .rubocop.yml'
        config = YAML.load(path.read.gsub(/(?<!\w)lib(?!\w)/, 'lib_original'))
        ((config['AllCops'] ||= {})['Exclude'] ||= []) << 'lib/**/*' << 'app/**/*'
        path.write("# This file was modified by DeepCover\n" + YAML.dump(config))
      end

      def patch
        patch_gemfile
        patch_rubocop
        patch_main_ruby_files
      end

      def cover
        coverage = Coverage.new
        each_dir_to_cover do |to_cover|
          original = to_cover.sub_ext('_original')
          FileUtils.cp_r(to_cover, original)
          Tools.dump_covered_code(original,
                                  coverage: coverage, root_path: @dest_root.to_s,
                                  dest_path: to_cover)
        end
        coverage.save(@dest_root.to_s)
      end

      def process
        Bundler.with_clean_env do
          system("cd #{@main_path} && #{@options[:command]}")
        end
      end

      def report
        coverage = Coverage.load @dest_root.to_s
        puts coverage.report(dir: @dest_root.to_s, **@options)
      end

      def bundle
        puts 'Running `bundle install`'
        Bundler.with_clean_env do
          `cd #{@dest_root} && bundle`
        end
      end

      def run
        if @options[:process]
          clear
          copy
          cover
          patch
          bundle if @options[:bundle]
          process
        end
        report
      end
    end
  end
end
