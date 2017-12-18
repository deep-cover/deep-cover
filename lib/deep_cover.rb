# frozen_string_literal: true

module DeepCover
  require_relative 'deep_cover/load'

  load_absolute_basics

  extend Base
  extend Config::Setter
end
DeepCover::GLOBAL_BINDING = binding

require './.deep_cover.rb' if File.exist?('./.deep_cover.rb')
DeepCover.start if %w[1 t true].include?(ENV['DEEP_COVER'])
