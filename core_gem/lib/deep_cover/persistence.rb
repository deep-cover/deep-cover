# frozen_string_literal: true

# This file is used by projects cloned with clone mode. As such, special care must be taken to
# be compatible with any projects.
# THERE MUST NOT BE ANY USE/REQUIRE OF DEPENDENCIES OF DeepCover HERE
# See deep-cover/core_gem/lib/deep_cover/setup/clone_mode_entry_template.rb for explanation of
# clone mode and of this top_level_module stuff.
top_level_module = Thread.current['_deep_cover_top_level_module'] || Object # rubocop:disable Lint/UselessAssignment

module top_level_module::DeepCover # rubocop:disable Naming/ClassAndModuleCamelCase
  require 'securerandom'
  class Persistence
    BASENAME = 'coverage.dc'
    TRACKER_TEMPLATE = 'trackers%{unique}.dct'

    attr_reader :dir_path
    def initialize(cache_directory)
      @dir_path = Pathname(cache_directory).expand_path
    end

    def save_trackers(tracker_hits_per_path)
      create_directory_if_needed
      basename = format(TRACKER_TEMPLATE, unique: SecureRandom.urlsafe_base64)

      dir_path.join(basename).binwrite(Marshal.dump(
                                           version: VERSION,
                                           tracker_hits_per_path: tracker_hits_per_path,
      ))
    end

    # returns a TrackerHitsPerPath
    def load_trackers
      tracker_hits_per_path_hashes = tracker_files.map do |full_path|
        Marshal.load(full_path.binread).yield_self do |version:, tracker_hits_per_path:| # rubocop:disable Security/MarshalLoad
          raise "dump version mismatch: #{version}, currently #{VERSION}" unless version == VERSION
          tracker_hits_per_path
        end
      end

      self.class.merge_tracker_hits_per_paths(*tracker_hits_per_path_hashes)
    end

    def merge_persisted_trackers
      tracker_hits_per_path = load_trackers
      return if tracker_hits_per_path.empty?
      tracker_files_before = tracker_files
      save_trackers(tracker_hits_per_path)
      tracker_files_before.each(&:delete)
    end

    def delete_trackers
      tracker_files.each(&:delete)
    end

    def clear_directory
      delete_trackers
      begin
        dir_path.rmdir
      rescue SystemCallError # rubocop:disable Lint/HandleExceptions
      end
    end

    def self.merge_tracker_hits_per_paths(*tracker_hits_per_path_hashes)
      return {} if tracker_hits_per_path_hashes.empty?

      result = tracker_hits_per_path_hashes[0].transform_values(&:dup)

      tracker_hits_per_path_hashes[1..-1].each do |tracker_hits_per_path|
        tracker_hits_per_path.each do |path, tracker_hits|
          matching_result = result[path]
          if matching_result.nil?
            result[path] = tracker_hits.dup
            next
          end

          if matching_result.size != tracker_hits.size
            raise "Attempting to merge trackers of different sizes: #{matching_result.size} vs #{tracker_hits.size}, for path #{path}"
          end

          tracker_hits.each_with_index do |nb_hits, i|
            matching_result[i] += nb_hits
          end
        end
      end

      result
    end

    private

    def create_directory_if_needed
      dir_path.mkpath
    end

    def tracker_files
      basename = format(TRACKER_TEMPLATE, unique: '*')
      Pathname.glob(dir_path.join(basename))
    end
  end
end
