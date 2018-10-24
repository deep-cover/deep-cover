# frozen_string_literal: true

module DeepCover
  class CLI
    desc 'clear [OPTIONS]', 'Clear coverage data and reports'
    def clear
      DeepCover.persistence.clear_directory
    end
  end
end
