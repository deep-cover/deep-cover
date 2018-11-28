# frozen_string_literal: true

module DeepCover
  module Tools::RubyEngines
    def on_mri?
      RUBY_ENGINE == 'ruby'
    end

    def on_jruby?
      RUBY_ENGINE == 'jruby'
    end

    def on_truffleruby?
      RUBY_ENGINE == 'truffleruby'
    end
  end
end
