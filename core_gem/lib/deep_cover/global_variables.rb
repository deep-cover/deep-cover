# frozen_string_literal: true

module DeepCover
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
