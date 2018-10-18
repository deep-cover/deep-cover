# frozen_string_literal: true

module DeepCover
  require_relative 'deep_cover/load'

  load_absolute_basics

  extend Base
  extend ConfigSetter
end
DeepCover::GLOBAL_BINDING = binding

require './.deep_cover.rb' if File.exist?('./.deep_cover.rb')

if ENV['DEEP_COVER_OPTIONS']
  DeepCover.config.set(YAML.load(ENV['DEEP_COVER_OPTIONS']))
end

# Any sub process should use the same config
ENV['DEEP_COVER_OPTIONS'] = YAML.dump(DeepCover.config.to_hash)

if %w[exec 1 t true].include?(ENV['DEEP_COVER'])
  # If we spawn more processes, then we don't want them clearing the trackers or doing reports.
  # We only want them to gather.
  ENV['DEEP_COVER'] = 'gather'
  DeepCover.start
  DeepCover.delete_trackers
  require_relative 'deep_cover/auto_run'
  DeepCover::AutoRun.run!('.').report!(**DeepCover.config)
elsif ENV['DEEP_COVER'] == 'gather'
  DeepCover.start
  require_relative 'deep_cover/auto_run'
  DeepCover::AutoRun.run!('.')
end
