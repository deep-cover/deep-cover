# frozen_string_literal: true

module DeepCover
  module StructWithOptions
    module Initializer
      def initialize(*args, **options)
        super(*args, options)
      end
    end

    def self.new(*args)
      Struct.new(*args, :options).tap do |klass|
        klass.include Initializer
        class << klass
          undef_method :new
        end
        klass.define_singleton_method(:new, Class.method(:new))
      end
    end
  end
end
