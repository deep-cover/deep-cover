# frozen_string_literal: true

module DeepCover
  class Config
    def initialize(notify = nil)
      @notify = notify
      @options = DEFAULTS.dup
    end

    def to_hash
      @options.dup
    end
    alias_method :to_h, :to_hash

    def ignore_uncovered(*keywords)
      if keywords.empty?
        @options[:ignore_uncovered]
      else
        check_uncovered(keywords)
        change(:ignore_uncovered, @options[:ignore_uncovered] | keywords)
      end
    end

    def detect_uncovered(*keywords)
      if keywords.empty?
        OPTIONALLY_COVERED - @options[:ignore_uncovered]
      else
        check_uncovered(keywords)
        change(:ignore_uncovered, @options[:ignore_uncovered] - keywords)
      end
    end

    def paths(paths = nil)
      if paths
        change(:paths, Array(paths).dup)
      else
        @options[:paths]
      end
    end

    def tracker_global(tracker_global = nil)
      if tracker_global
        change(:tracker_global, tracker_global)
      else
        @options[:tracker_global]
      end
    end

    def reset
      DEFAULTS.each do |key, value|
        change(key, value)
      end
    end

    private

    def check_uncovered(keywords)
      unknown = keywords - OPTIONALLY_COVERED
      raise ArgumentError, "unknown options: #{unknown.join(', ')}" unless unknown.empty?
    end

    def change(option, value)
      if @options[option] != value
        @options[option] = value.freeze
        @notify.config_changed(option) if @notify.respond_to? :config_changed
      end
      self
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
