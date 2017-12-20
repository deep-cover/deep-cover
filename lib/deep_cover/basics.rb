# frozen_string_literal: true

# Basic constants without any dependencies are here
module DeepCover
  DEFAULTS = {
               ignore_uncovered: [].freeze,
               paths: %w[./app ./lib].freeze,
               allow_partial: false,
               tracker_global: '$_cov',
             }.freeze

  OPTIONALLY_COVERED = %i[case_implicit_else default_argument raise trivial_if].freeze
end
