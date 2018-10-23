#!/usr/bin/env ruby
# frozen_string_literal: true

require 'thor'

module DeepCover
  require 'deep-cover' # This deep-cover requiring deep-cover-core, so this can't use `#require_relative`
  bootstrap

  class CLI < Thor
    # Just fail when you get an unknown option
    check_unknown_options!

    # If the default value of a option doesn't match its type, something is wrong.
    check_default_type!

    # Every top-level commands are defined in a different file, which add their method to this class
    DeepCover.require_relative_dir 'cli'

    # Adding all of the ignore-something options
    OPTIONALLY_COVERED_MAP = OPTIONALLY_COVERED.map do |optional|
      [:"ignore_#{optional}", optional]
    end.to_h.freeze
    OPTIONALLY_COVERED_MAP.each do |cli_option, short_name|
      default = DeepCover.config.ignore_uncovered.include?(short_name)
      class_option cli_option, type: :boolean, default: default
    end

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
    end
  end
end
