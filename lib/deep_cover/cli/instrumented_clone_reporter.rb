require 'yaml'
require 'tmpdir'

module DeepCover
  module CLI
    class InstrumentedCloneReporter
      include Tools

      def initialize(gem_path, command: 'rake', **options)
        @command = command
        @options = options
        @root_path = File.expand_path(gem_path)
        if File.exist?(File.join(@root_path, 'Gemfile'))
          @gem_relative_path = '' # Typical case
        else
          # E.g. rails/activesupport
          @gem_relative_path = File.basename(@root_path)
          @root_path = File.dirname(@root_path)
          raise "Can't find Gemfile" unless File.exist?(File.join(@root_path, 'Gemfile'))
        end
        @dest_root = File.expand_path('~/test_deep_cover')
        @dest_root = Dir.mktmpdir("deep_cover_test") unless Dir.exist?(@dest_root)
        `rm -rf #{@dest_root}/* #{@dest_root}/.*`
        @main_path = File.expand_path(File.join(@dest_root, @gem_relative_path))
      end

      def copy
        @copy ||= `cp -r #{@root_path}/* #{@dest_root} && cp #{@root_path}/.* #{@dest_root}`
      end

      def patch_ruby_file(ruby_file)
        content = File.read(ruby_file)
        # Insert our code after leading comments:
        content.sub!(/^((#.*\n+)*)/, "#{$1}require 'deep_cover/auto_run';DeepCover::AutoRun.run! '#{@dest_root}';")
        File.write(ruby_file, content)
      end

      def each_gem_path
        return to_enum __method__ unless block_given?
        yield @main_path
      end

      def patch_main_ruby_files
        each_gem_path do |dest_path|
          main = File.join(dest_path, 'lib/*.rb')
          Dir.glob(main).each do |main|
            puts "Patching #{main}"
            patch_ruby_file(main)
          end
        end
      end

      def patch_gemfile
        gemfile = File.expand_path(File.join(@dest_root, 'Gemfile'))
        content = File.read(gemfile)
        unless content =~ /gem 'deep-cover'/
          puts "Patching Gemfile #{gemfile}"
          File.write(gemfile, [
            "# This file was modified by DeepCover",
            content,
            "gem 'deep-cover', path: '#{File.expand_path(__dir__ + '/../../../')}'",
            '',
          ].join("\n"))
        end
      end

      def patch_rubocop
        path = File.expand_path(File.join(@dest_root, '.rubocop.yml'))
        return unless File.exists?(path)
        puts "Patching .rubocop.yml"
        config = YAML.load(File.read(path).gsub(/(?<!\w)lib(?!\w)/, 'lib_original'))
        ((config['AllCops'] ||= {})['Exclude'] ||= []) << 'lib/**/*' << 'app/**/*'
        File.write(path, "# This file was modified by DeepCover\n" + YAML.dump(config))
      end

      def patch
        patch_gemfile
        patch_rubocop
        patch_main_ruby_files
      end

      def cover
        coverage = Coverage.new
        each_gem_path do |dest_path|
          `cp -R #{dest_path}/lib #{dest_path}/lib_original`
          Tools.dump_covered_code(File.join(dest_path, 'lib_original'),
            coverage: coverage, root_path: @dest_root,
            dest_path: File.join(dest_path, 'lib'))
        end
        coverage.save(@dest_root)
      end

      def process
        Bundler.with_clean_env do
          system("cd #{@main_path} && #{@command}", out: $stdout, err: :out)
        end
      end

      def report
        coverage = Coverage.load @dest_root
        puts coverage.report(dir: @dest_root, **@options)
      end

      def bundle
        puts "Running `bundle install`"
        Bundler.with_clean_env do
          `cd #{@dest_root} && bundle`
        end
      end

      def run
        copy
        cover
        patch
        bundle
        process
        report
      end
    end
  end
end
