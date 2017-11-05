require 'yaml'
require 'tmpdir'

module DeepCover
  module CLI
    class InstrumentedCloneReporter
      include Tools
      # matches regular files, .files, ..files, but not '.' or '..'
      GLOB_ALL_CONTENT = '{,.[^.],..?}*'

      def initialize(gem_path, command: 'rake', **options)
        @command = command
        @options = options
        @root_path = gem_path = Pathname.new(gem_path).expand_path
        unless @root_path.join('Gemfile').exist?
          # E.g. rails/activesupport
          @root_path = @root_path.dirname
          raise "Can't find Gemfile" unless @root_path.join('Gemfile').exist?
        end
        @dest_root = Pathname('~/test_deep_cover').expand_path
        @dest_root = Pathname.new(Dir.mktmpdir("deep_cover_test")) unless @dest_root.exist?

        FileUtils.rm_rf(Dir.glob("#{@dest_root}/#{GLOB_ALL_CONTENT}"))
        gem_relative_path = gem_path.relative_path_from(@root_path)
        @main_path = @dest_root.join(gem_relative_path)
      end

      def copy
        return true if @copied
        FileUtils.cp_r(Dir.glob("#{@root_path}/#{GLOB_ALL_CONTENT}"), @dest_root)
        @copied = true
      end

      def patch_ruby_file(ruby_file)
        content = File.read(ruby_file)
        # Insert our code after leading comments:
        content.sub!(/^((#.*\n+)*)/, "#{$1}require 'deep_cover/auto_run';DeepCover::AutoRun.run! '#{@dest_root}';")
        File.write(ruby_file, content)
      end

      def each_gem_path
        return to_enum __method__ unless block_given?
        if @main_path.join('lib').exist?
          yield @main_path
        else # Rails style
          Pathname.glob(@main_path.join('*/lib')).each{|p| yield p.dirname}
        end
      end

      def patch_main_ruby_files
        each_gem_path do |dest_path|
          main = dest_path.join('lib/*.rb')
          Dir.glob(main).select{|p| File.file?(p) }.each do |main|
            puts "Patching #{main}"
            patch_ruby_file(main)
          end
        end
      end

      def patch_gemfile
        gemfile = @dest_root.join('Gemfile')
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
        path = @dest_root.join('.rubocop.yml')
        return unless path.exist?
        puts "Patching .rubocop.yml"
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
        each_gem_path do |dest_path|
          FileUtils.cp_r("#{dest_path}/lib", "#{dest_path}/lib_original")
          Tools.dump_covered_code(File.join(dest_path, 'lib_original'),
            coverage: coverage, root_path: @dest_root.to_s,
            dest_path: File.join(dest_path, 'lib'))
        end
        coverage.save(@dest_root.to_s)
      end

      def process
        Bundler.with_clean_env do
          system("cd #{@main_path} && #{@command}")
        end
      end

      def report
        coverage = Coverage.load @dest_root.to_s
        puts coverage.report(dir: @dest_root.to_s, **@options)
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
        bundle if @options.fetch(:bundle, true)
        process
        report
      end
    end
  end
end
