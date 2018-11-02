# frozen_string_literal: true

# This file is required by absolute path in the entry_points when doing clone mode.
# THERE MUST NOT BE ANY USE/REQUIRE OF DEPENDENCIES OF DeepCover HERE
#
# Doing things this way allows us to avoid all kinds of trouble from possibly patching
# the Gemfile.

# Things that must be done from this file:
# * Setup DeepCover::CloneModeEntry, which only needs to dump the trackers at the end.
# * It may be called multiple times, so don't dump multiple times.

require_relative '../tools/after_tests'
require_relative '../core_ext/exec_callbacks'

module DeepCover
  module CloneModeEntry
    def self.setup(global_name, cache_directory)
      return if already_setup?
      Tools::AfterTests.after_tests { save(global_name, cache_directory) }
      ExecCallbacks.before_exec { save(global_name, cache_directory) }
      @already_setup = true
    end

    def self.save(global_name, cache_directory)
      return if saved?

      require_relative '../global_variables'
      require_relative '../persistence'
      require_relative '../version'

      Persistence.new(cache_directory).save_trackers(GlobalVariables.tracker_hits_per_paths(global_name))
      @saved = true
    end

    def self.already_setup?
      @already_setup ||= false
    end

    def self.saved?
      @saved ||= false
    end
  end
end
