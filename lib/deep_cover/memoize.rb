# frozen_string_literal: true

module DeepCover
  bootstrap

  # Memoize is a quick way to prepend a module that defines
  # the memoized methods as `@_cache ||= super.freeze`
  # It also refines `freeze` to precache memoized methods
  #
  module Memoize
    def self.included(base)
      base.extend ClassMethods
    end

    def freeze
      self.class.memoized.each do |method|
        send method
      end
      super
    end

    module ClassMethods
      def memoized
        @memoized ||= [].freeze
      end

      def memoizer_module
        @memoizer_module ||= begin
          mod = const_set(:Memoizer, Module.new)
          prepend mod
          mod
        end
      end

      def memoize(*methods)
        @memoized = (memoized | methods).freeze

        methods.each do |method|
          memoizer_module.module_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{method}                    # def foo
              @_#{method} ||= super.freeze   #   @_foo ||= super.freeze
            end                              # end
          RUBY
        end
      end
    end
  end
end
