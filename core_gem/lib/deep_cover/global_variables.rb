# frozen_string_literal: true

# This file is used by projects cloned with clone mode. As such, special care must be taken to
# be compatible with any projects.
# THERE MUST NOT BE ANY USE/REQUIRE OF DEPENDENCIES OF DeepCover HERE
# See deep-cover/core_gem/lib/deep_cover/setup/clone_mode_entry_template.rb for explanation of
# clone mode and of this top_level_module stuff.
top_level_module = Thread.current['_deep_cover_top_level_module'] || Object # rubocop:disable Lint/UselessAssignment

module top_level_module::DeepCover # rubocop:disable Naming/ClassAndModuleCamelCase
  module GlobalVariables
    def self.trackers(global_name = nil)
      @trackers ||= {}
      global_name ||= DeepCover.config.tracker_global
      @trackers[global_name] ||= eval("#{global_name} ||= {}") # rubocop:disable Security/Eval
    end

    def self.paths(global_name = nil)
      @paths ||= {}
      global_name ||= DeepCover.config.tracker_global
      @paths[global_name] ||= eval("#{global_name}_p ||= {}") # rubocop:disable Security/Eval
    end

    def self.tracker_hits_per_paths(global_name = nil)
      cur_trackers = self.trackers(global_name)
      tracker_hits_per_paths = paths(global_name).map do |index, path|
        [path, cur_trackers[index]]
      end
      tracker_hits_per_paths.to_h
    end
  end
end
