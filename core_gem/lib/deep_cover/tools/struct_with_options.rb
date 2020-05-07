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
      end
    end
  end
end
