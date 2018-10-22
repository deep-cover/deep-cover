# frozen_string_literal: true

# This is a template for the setup code used by the clone mode.
# Clone mode will copy this file and gsub some "global variables" with their value.
# The the fake global variables are: $_cache_directory, $_core_gem_lib_directory, $_global_name
# This template is important because with the anonymous top-level module, it becomes problematic
# to call the content of this file from the place that required it. Doing it with a template means
# that it is not necessary to do anything beyond requiring the file. It feels cleaner than the
# alternatives I thought of.

# It is important to avoid using any of deep-cover's dependencies (from other gems), because they may not be in
# the Gemfile of the project being cloned, and so will not be found.

# In order to avoid any possible name clashing with a DeepCover that would be used in the program
# being covered with clone mode, we create a unique top-level module under which we nest everything
# that we need. (The main use-case for this is when doing coverage of DeepCover itself)
top_level_module = Module.new

module top_level_module::DeepCover # rubocop:disable Naming/ClassAndModuleCamelCase
  def self.setup
    Tools::AfterTests.after_tests { save }
    ExecCallbacks.before_exec { save }
  end

  def self.save
    return if saved?

    Persistence.new($_cache_directory).save_trackers(GlobalVariables.tracker_hits_per_paths($_global_name))
    @saved = true
  end

  def self.saved?
    @saved ||= false
  end
end

# The files that we need all use this top-level module when it is defined. We avoid any kind of race-condition
# by using Thread.current instead of a global variable. (Think of what would happen if another thread decided to
# require 'deep-cover' while this thread is loading it's special top-level dependencies)
Thread.current['_deep_cover_top_level_module'] = top_level_module
# To avoid any issue, we load the files instead of requiring them. Since this file is being required, the
# result is the same, but if, for any reason, this file or another template gets executed again, then there will be
# a new top-level module, so we must fill it correctly, which means loading the files again.
load $_core_gem_lib_directory + '/deep_cover/global_variables.rb'
load $_core_gem_lib_directory + '/deep_cover/persistence.rb'
load $_core_gem_lib_directory + '/deep_cover/version.rb'
load $_core_gem_lib_directory + '/deep_cover/core_ext/exec_callbacks.rb'
load $_core_gem_lib_directory + '/deep_cover/tools/after_tests.rb'

Thread.current['_deep_cover_top_level_module'] = nil

# This is really just to make debugging less of a pain, it gives a way to the code to access the anonymous top-level module
module DeepCover
  CLONE_MODE_ENTRY_TOP_LEVEL_MODULES ||= []
end
DeepCover::CLONE_MODE_ENTRY_TOP_LEVEL_MODULES << top_level_module

# Activate everything!
top_level_module::DeepCover.setup
