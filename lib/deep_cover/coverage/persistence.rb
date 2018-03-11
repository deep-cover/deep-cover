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
        load_trackers if with_trackers
        load_coverage
      end

      def save(coverage)
        create_if_needed
        delete_trackers
        save_coverage(coverage)
      end

      def save_trackers(global)
        saved?
        trackers = eval(global) # rubocop:disable Security/Eval
        # Some testing involves more than one process, some of which don't run any of our covered code.
        # Don't save anything if that's the case
        return if trackers.nil?
        basename = format(TRACKER_TEMPLATE, unique: SecureRandom.urlsafe_base64)
        dir_path.join(basename).binwrite(Marshal.dump(
                                             version: DeepCover::VERSION,
                                             global: global,
                                             trackers: trackers,
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

      def load_trackers
        tracker_files.each do |full_path|
          Marshal.load(full_path.binread).tap do |version:, global:, trackers:|
            raise "dump version mismatch: #{version}, currently #{DeepCover::VERSION}" unless version == DeepCover::VERSION
            merge_trackers(eval("#{global} ||= {}"), trackers) # rubocop:disable Security/Eval
          end
        end
      end
      # rubocop:enable Security/MarshalLoad

      def merge_trackers(hash, to_merge)
        hash.merge!(to_merge) do |_key, current, to_add|
          next to_add if current.empty?
          next current if to_add.empty?
          unless current.size == to_add.size
            warn "Merging trackers of different sizes: #{current.size} vs #{to_add.size}"
          end
          to_add.zip(current).map { |a, b| a + b }
        end
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
