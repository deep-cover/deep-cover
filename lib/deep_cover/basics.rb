# frozen_string_literal: true

# Basic constants without any dependencies are here
module DeepCover
  DEFAULTS = {
               ignore_uncovered: [].freeze,
               paths: %w[./app ./lib].freeze,
               allow_partial: false,
             }.freeze
end
