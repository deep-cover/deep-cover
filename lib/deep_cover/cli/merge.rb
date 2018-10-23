# frozen_string_literal: true

module DeepCover
  class CLI
    desc 'merge [OPTIONS]', 'Merge all multiple coverage data into one'
    def merge
      DeepCover.persistence.merge_persisted_trackers
    end
  end
end
