# frozen_string_literal: true

module DeepCover
  require 'securerandom'
  class Coverage
    class Persistence
      BASENAME = 'coverage.dc'
      TRACKER_TEMPLATE = 'trackers%{unique}.dct'

      attr_reader :dir_path
      def initialize(dest_path, dirname)
        @dir_path = Pathname(dest_path).join(dirname).expand_path
      end

      def load(with_trackers: true)
        saved?
        cov = load_coverage
        cov.tracker_storage_per_path.tracker_hits_per_path = load_trackers if with_trackers
        cov
      end

      def save(coverage)
        create_if_needed
        delete_trackers
        save_coverage(coverage)
      end

      def save_trackers(tracker_hits_per_path)
        saved?
        basename = format(TRACKER_TEMPLATE, unique: SecureRandom.urlsafe_base64)
        dir_path.join(basename).binwrite(Marshal.dump(
                                             version: DeepCover::VERSION,
                                             tracker_hits_per_path: tracker_hits_per_path,
        ))
      end

      def saved?
        raise "Can't find folder '#{dir_path}'" unless dir_path.exist?
        self
      end

      private

      def create_if_needed
        dir_path.mkpath
      end

      def save_coverage(coverage)
        dir_path.join(BASENAME).binwrite(Marshal.dump(
                                             version: DeepCover::VERSION,
                                             coverage: coverage,
        ))
      end

      # rubocop:disable Security/MarshalLoad
      def load_coverage
        Marshal.load(dir_path.join(BASENAME).binread).tap do |version:, coverage:|
          raise "dump version mismatch: #{version}, currently #{DeepCover::VERSION}" unless version == DeepCover::VERSION
          return coverage
        end
      end

      # returns a TrackerHitsPerPath
      def load_trackers
        tracker_files.map do |full_path|
          Marshal.load(full_path.binread).yield_self do |version:, tracker_hits_per_path:|
            raise "dump version mismatch: #{version}, currently #{DeepCover::VERSION}" unless version == DeepCover::VERSION
            tracker_hits_per_path
          end
        end.inject(:merge!)
      end
      # rubocop:enable Security/MarshalLoad

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
