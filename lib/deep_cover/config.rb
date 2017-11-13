# frozen_string_literal: true
module DeepCover
  class Config
    DEFAULTS = {
      ignore_uncovered: [],
      paths: %w[./app ./lib],
      allow_partial: false,
    }

    def initialize(**options)
      @options = copy(DEFAULTS.merge(options))
    end

    def to_hash
      copy(@options)
    end
    alias_method :to_h, :to_hash

    def ignore_uncovered(*keywords)
      check_uncovered(keywords)
      @options[:ignore_uncovered] |= keywords
      self
    end

    def detect_uncovered(*keywords)
      check_uncovered(keywords)
      @options[:ignore_uncovered] -= keywords
      self
    end

    def paths(paths)
      @options[:paths] = paths
      self
    end

    private
    def check_uncovered(keywords)
      unknown = keywords - Analyser.optionally_covered
      raise ArgumentError, "unknown options: #{unknown.join(', ')}" unless unknown.empty?
    end

    def copy(h)
      h.dup.transform_values(&:dup)
    end

    module Setter
      def config
        @config ||= Config.new
      end

      def configure(&block)
        raise "Must provide a block" unless block
        case block.arity
        when 0
          config.instance_eval(&block)
        when 1
          block.call(config)
        end
      end
    end
  end
end
