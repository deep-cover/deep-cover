# frozen_string_literal: true

module DeepCover
  module Tools::RubyEngines
    def mri?
      RUBY_ENGINE == 'ruby'
    end

    def jruby?
      RUBY_ENGINE == 'jruby'
    end

    def truffle?
      RUBY_ENGINE == 'truffleruby'
    end
    alias_method :truffleruby?, :truffle?
  end
end
