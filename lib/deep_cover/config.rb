require 'backports/2.4.0/false_class/dup'
require 'backports/2.4.0/true_class/dup'

module DeepCover
  class Config
    DEFAULTS = {
      ignore_uncovered: [],
      paths: %w[./app ./lib],
      allow_partial: false,
    }

    def initialize
      @options = copy(DEFAULTS)
    end

    def to_hash
      copy(@options)
    end
    alias_method :to_h, :to_hash

    def ignore_uncovered(*keywords)
      @options[:ignore_uncovered] -= keywords
      self
    end

    def detect_uncovered(*keywords)
      @options[:ignore_uncovered] += keywords
      self
    end

    def paths(paths)
      @options[:paths] = paths
      self
    end

    private
    def copy(h)
      h.dup.transform_values(&:dup)
    end

    module Setter
      def configure(&block)
        @config ||= Config.new

        raise "Must provide a block" unless block
        case block.arity
        when 0
          @config.instance_eval(&block)
        when 1
          block.call(@config)
        end
      end
    end
  end
end
