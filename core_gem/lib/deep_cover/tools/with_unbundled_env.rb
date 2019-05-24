# frozen_string_literal: true

module DeepCover
  module Tools
    module WithUnbundledEnv
      extend self
      # Bundler is changing from with_clean_env to with_unbundled_env in 2.0
      def with_unbundled_env
        if Bundler.respond_to?(:with_unbundled_env)
          Bundler.with_unbundled_env { yield }
        else
          Bundler.with_clean_env { yield }
        end
      end
    end
  end
end
