# frozen_string_literal: true

# This file is used by projects cloned with clone mode. As such, special care must be taken to
# be compatible with any projects.
# THERE MUST NOT BE ANY USE/REQUIRE OF DEPENDENCIES OF DeepCover HERE
# See deep-cover/core_gem/lib/deep_cover/setup/clone_mode_entry_template.rb for explanation of
# clone mode and of this top_level_module stuff.
top_level_module = Thread.current['_deep_cover_top_level_module'] || Object

module top_level_module::DeepCover # rubocop:disable Naming/ClassAndModuleCamelCase
  module GlobalVariables
    def self.trackers(global_name = nil)
      @trackers ||= {}
      global_name ||= DeepCover.config.tracker_global
      @trackers[global_name] ||= eval("#{global_name} ||= {}") # rubocop:disable Security/Eval
    end

    def self.path_per_index(global_name = nil)
      @path_per_index ||= {}
      global_name ||= DeepCover.config.tracker_global
      @path_per_index[global_name] ||= eval("#{global_name}_p ||= {}") # rubocop:disable Security/Eval
    end

    def self.tracker_hits_per_path(global_name = nil)
      cur_trackers = self.trackers(global_name)
      hits_per_path = path_per_index(global_name).map do |index, path|
        [path, cur_trackers[index]]
      end
      hits_per_path.to_h
    end
  end
end
