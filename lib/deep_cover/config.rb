# frozen_string_literal: true

module DeepCover
  class Config
    DEFAULTS = {
                 ignore_uncovered: [],
                 paths: %w[./app ./lib],
                 allow_partial: false,
               }.freeze

    def initialize(notify = nil, **options)
      @notify = notify
      @options = copy(DEFAULTS.merge(options))
    end

    def to_hash
      copy(@options)
    end
    alias_method :to_h, :to_hash

    def ignore_uncovered(*keywords)
      check_uncovered(keywords)
      change(:ignore_uncovered, @options[:ignore_uncovered] | keywords)
    end

    def detect_uncovered(*keywords)
      check_uncovered(keywords)
      change(:ignore_uncovered, @options[:ignore_uncovered] - keywords)
    end

    def paths(paths = nil)
      if paths
        change(:paths, Array(paths).dup)
      else
        @options[:paths]
      end
    end

    private

    def check_uncovered(keywords)
      unknown = keywords - Analyser.optionally_covered
      raise ArgumentError, "unknown options: #{unknown.join(', ')}" unless unknown.empty?
    end

    def change(option, value)
      if @options[option] != value
        @options[option] = value.freeze
        @notify.config_changed(option) if @notify.respond_to? :config_changed
      end
      self
    end

    def copy(h)
      h.dup.transform_values(&:dup).transform_values(&:freeze)
    end

    module Setter
      def config(notify = self)
        @config ||= Config.new(notify)
      end

      def configure(&block)
        raise 'Must provide a block' unless block
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
