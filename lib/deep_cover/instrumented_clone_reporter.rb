# frozen_string_literal: true

require 'tmpdir'

module DeepCover
  require_relative 'cover_cloned_tree'

  class InstrumentedCloneReporter
    include Tools
    # matches regular files, .files, ..files, but not '.' or '..'
    GLOB_ALL_CONTENT = '{,.[^.],..?}*'

    def initialize(**options)
      @options = CLI_DEFAULTS.merge(options)
      @root_path = @source_path = Pathname.new('.').expand_path
      unless @root_path.join('Gemfile').exist?
        # E.g. rails/activesupport
        @root_path = @root_path.dirname
        raise "Can't find Gemfile in #{@root_path}" unless @root_path.join('Gemfile').exist?
      end
      path = Pathname('~/test_deep_cover').expand_path
      if path.exist?
        @dest_root = path.join(@source_path.basename)
        @dest_root.mkpath
      else
        @dest_root = Pathname.new(Dir.mktmpdir('deep_cover_test'))
      end

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

    def style
      if @source_path.join('config/environments/test.rb').exist?
        :rails
      elsif @source_path.join('core_gem').exist?
        :self_coverage
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

    module SelfCoverage
      include Gem
      def each_gem_path
        yield @main_path
        yield @main_path.join('core_gem')
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

    def create_entry_point_file
      require 'tempfile'
      file = Tempfile.new(['deep_cover_entry_point', '.rb'])
      template = File.read(DeepCover::CORE_GEM_LIB_DIRECTORY + '/deep_cover/setup/clone_mode_entry_template.rb')

      cache_directory = DeepCover.config.cache_directory.to_s
      tracker_global = DeepCover.config.tracker_global

      # Those are the fake global variables that we actually replace as we copy the template over
      template.gsub!('$_cache_directory', cache_directory.inspect)
      template.gsub!('$_global_name', tracker_global.inspect)
      template.gsub!('$_core_gem_lib_directory', DeepCover::CORE_GEM_LIB_DIRECTORY.inspect)

      file.write(template)
      file.close

      # We dont want the file to be removed, this way it stays as long as the clones directory does.
      ObjectSpace.undefine_finalizer(file)

      file.path
    end

    def patch_rubocop
      path = @dest_root.join('.rubocop.yml')
      return unless path.exist?
      puts 'Patching .rubocop.yml'
      config = YAML.load(path.read)
      all_cop_excludes = ((config['AllCops'] ||= {})['Exclude'] ||= [])

      # Ensure they end with a '/'
      original_root = File.join(File.expand_path(@root_path), '')
      clone_root = File.join(File.expand_path(@dest_root), '')

      paths_to_ignore = DeepCover.all_tracked_file_paths
      paths_to_ignore.select! { |p| p.start_with?(original_root) }
      paths_to_ignore.map! { |p| p.sub(original_root, clone_root) }

      all_cop_excludes.concat(paths_to_ignore)
      path.write("# This file was modified by DeepCover\n" + YAML.dump(config))
    end

    def patch
      patch_rubocop
    end

    def remove_deep_cover_config
      path = @dest_root.join('.deep_cover.rb')
      return unless path.exist?
      File.delete(path)
    end

    def cover
      entry_point_path = create_entry_point_file
      Tools.cover_cloned_tree(DeepCover.all_tracked_file_paths,
                              clone_root: @dest_root,
                              original_root: @root_path) do |source|
        source.sub(/\A(#.*\n|\s+)*/) do |header|
          "#{header}require #{entry_point_path.inspect};"
        end
      end
    end

    def process
      DeepCover.delete_trackers
      system({'DISABLE_SPRING' => 'true', 'DEEP_COVER_OPTIONS' => nil}, "cd #{@main_path} && #{@options[:command]}")
    end

    def report
      coverage = Coverage.load
      puts coverage.report(**@options)
    end

    def run
      clear
      copy
      cover
      patch
      remove_deep_cover_config
      process
      report
    end
  end
end
