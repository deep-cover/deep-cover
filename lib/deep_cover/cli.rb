#!/usr/bin/env ruby
# frozen_string_literal: true

require 'thor'

module DeepCover
  # can't use `#require_relative`: This is gem deep-cover requiring from gem deep-cover-core
  # We don't want the config to be loaded right now, because we may move the current_work_dir somewhere else.
  require 'deep_cover/setup/deep_cover_without_config'

  bootstrap

  class CLI < Thor
    # Consider defaults only for display
    def self.build_option(arg, options, scope)
      default = options.delete(:default)
      options[:desc] = "#{options[:desc]} (default: #{default})" if default
      super(arg, options, scope)
    end

    require_relative 'cli/tools'

    # Just fail when you get an unknown option
    check_unknown_options!

    # If the default value of a option doesn't match its type, something is wrong.
    check_default_type!

    # Every top-level commands are defined in a different file, which add their method to this class
    DeepCover.require_relative_dir 'cli/commands'

    default_command :short_help

    # Adding all of the ignore-something class options
    OPTIONALLY_COVERED_MAP = OPTIONALLY_COVERED.map do |optional|
      [:"ignore_#{optional}", optional]
    end.to_h.freeze
    OPTIONALLY_COVERED_MAP.each do |cli_option, short_name|
      default = DeepCover.config.ignore_uncovered.include?(short_name)
      class_option cli_option, type: :boolean, description: "Default: #{default}"
    end

    class_option :change_directory, desc: 'Runs as if deep-cover was started in <path>', type: :string, aliases: '-C', default: '.'

    # exit_code should be non-zero when the parsing fails
    def self.exit_on_failure?
      true
    end

    no_commands do
      # We have some special handling for some of the options
      # We do this here, methods just need to call processed_options instead of options.
      def processed_options
        @processed_options ||= nil
        return @processed_options if @processed_options

        new_options = options.dup
        new_options[:output] = false if ['false', 'f', ''].include?(new_options[:output])

        # Turn all the ignore-x into entries in :ignore_uncovered
        ignored = new_options[:ignore_uncovered] = []
        OPTIONALLY_COVERED_MAP.each do |cli_option, option|
          ignored << option if new_options.delete(cli_option)
        end

        @processed_options = new_options.transform_keys(&:to_sym)
      end

      # Before we actually execute any of the commands, we want to change directory if that option was given.
      # And then we want to setup the configuration
      def invoke_command(*args)
        if options[:change_directory]
          root_path = File.expand_path(options[:change_directory])
          unless File.exist?(root_path)
            warn set_color(DeepCover::Tools.strip_heredoc(<<-MSG), :red)
              bad value for option --change-directory: #{root_path.inspect} is not a valid directory
            MSG
            exit(1)
          end
          Dir.chdir(root_path)
          # TODO: We need way to turn on DEBUG
          # warn "(in #{root_path})"
        end

        # We need to wait until now to setup the configuration, because it will store absolute paths
        # in ENV['DEEP_COVER_OPTIONS'], so we must wait until the change_directory was applied.
        require 'deep_cover/setup/deep_cover_config'
        super
      end
    end
  end
end
