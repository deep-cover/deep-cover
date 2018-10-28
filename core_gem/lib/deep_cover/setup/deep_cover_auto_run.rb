# frozen_string_literal: true

# This file is called from `require 'deep-cover'`
#
# Based on the DEEP_COVER environment variable, we automatically start the
# covering. This way, users just need to require a file and the CLI will
# be able to automatically do the coverage.

if %w[exec 1 t true].include?(ENV['DEEP_COVER'])
  # If we spawn more processes, then we don't want them clearing the trackers or doing reports.
  # We only want them to gather.
  ENV['DEEP_COVER'] = 'gather'
  DeepCover.start
  DeepCover.delete_trackers
  require_relative '../auto_run'
  DeepCover::AutoRun.run!('.').report!(**DeepCover.config)
elsif ENV['DEEP_COVER'] == 'gather'
  DeepCover.start
  require_relative '../auto_run'
  DeepCover::AutoRun.run!('.')
end
