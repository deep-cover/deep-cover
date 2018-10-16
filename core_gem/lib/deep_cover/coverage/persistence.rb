# frozen_string_literal: true

module DeepCover
  require 'securerandom'
  class Coverage
    class Persistence
      BASENAME = 'coverage.dc'
      TRACKER_TEMPLATE = 'trackers%{unique}.dct'

      attr_reader :dir_path
      def initialize(dest_path, dirname = 'deep_cover')
        @dir_path = Pathname(dest_path).join(dirname).expand_path
      end

      def save_trackers(tracker_hits_per_path)
        create_directory_if_needed
        basename = format(TRACKER_TEMPLATE, unique: SecureRandom.urlsafe_base64)

        dir_path.join(basename).binwrite(Marshal.dump(
                                             version: DeepCover::VERSION,
                                             tracker_hits_per_path: tracker_hits_per_path,
        ))
      end

      # returns a TrackerHitsPerPath
      def load_trackers
        tracker_files.map do |full_path|
          Marshal.load(full_path.binread).yield_self do |version:, tracker_hits_per_path:| # rubocop:disable Security/MarshalLoad
            raise "dump version mismatch: #{version}, currently #{DeepCover::VERSION}" unless version == DeepCover::VERSION
            tracker_hits_per_path
          end
        end.inject(:merge!)
      end

      private

      def create_directory_if_needed
        dir_path.mkpath
      end

      def tracker_files
        basename = format(TRACKER_TEMPLATE, unique: '*')
        Pathname.glob(dir_path.join(basename))
      end

      def delete_trackers
        tracker_files.each(&:delete)
      end
    end
  end
end
