# frozen_string_literal: true

# This file is called from `require 'deep-cover'` and from the CLI, it may have changed work directory
#
# This initializes DeepCover's configuration from a configuration file
# and from an environment variable, if present.
# Then, we set the enrionment variable to the current configuration so that
# child process are running with the same options.

require './.deep_cover.rb' if File.exist?('./.deep_cover.rb')

if ENV['DEEP_COVER_OPTIONS']
  DeepCover.config.load_hash_for_serialize(YAML.load(ENV['DEEP_COVER_OPTIONS']))
end

# Any sub process should use the same config as this one
# Just leaving DEEP_COVER_OPTIONS as is means only options passed to this process will propagate,
# but we want, at the very least, that every sub-process use the same cache_directory.
ENV['DEEP_COVER_OPTIONS'] = YAML.dump(DeepCover.config.to_hash_for_serialize)
