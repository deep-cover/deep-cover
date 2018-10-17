# frozen_string_literal: true

module DeepCover
  class Config
    def initialize(notify = nil)
      @notify = nil
      @options = {ignore_uncovered: []}
      set(**DEFAULTS)
      @notify = notify
    end

    def to_hash
      @options.dup
    end
    alias_method :to_h, :to_hash

    def ignore_uncovered(*keywords, &block)
      if block
        raise ArgumentError, "wrong number of arguments (given #{keywords.size}, expected 0..1)" if keywords.size > 1
        keywords << Node.unique_filter if keywords.empty?
        Node.create_filter(keywords.first, &block)
      end
      if keywords.empty?
        @options[:ignore_uncovered]
      else
        keywords = check_uncovered(keywords)
        change(:ignore_uncovered, @options[:ignore_uncovered] | keywords)
      end
    end

    def detect_uncovered(*keywords)
      raise ArgumentError, 'No block is accepted' if block_given?
      if keywords.empty?
        OPTIONALLY_COVERED - @options[:ignore_uncovered]
      else
        keywords = check_uncovered(keywords)
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

    def reporter(reporter = nil)
      if reporter
        change(:reporter, reporter)
      else
        @options[:reporter]
      end
    end

    def output(path_or_false = nil)
      if path_or_false != nil
        change(:output, path_or_false)
      else
        @options[:output]
      end
    end

    def cache_directory(cache_directory = nil)
      if cache_directory
        change(:cache_directory, File.expand_path(cache_directory))
      else
        @options[:cache_directory]
      end
    end

    def allow_partial(allow_partial = nil)
      if allow_partial != nil
        change(:allow_partial, allow_partial)
      else
        @options[:allow_partial]
      end
    end

    def reset
      DEFAULTS.each do |key, value|
        change(key, value)
      end
      self
    end

    def set(**options)
      @options[:ignore_uncovered] = [] if options.has_key?(:ignore_uncovered)
      options.each do |key, value|
        public_send key, value
      end
      self
    end

    private

    def check_uncovered(keywords)
      keywords = keywords.first if keywords.size == 1 && keywords.first.is_a?(Array)
      unknown = keywords - OPTIONALLY_COVERED
      raise ArgumentError, "unknown options: #{unknown.join(', ')}" unless unknown.empty?
      keywords
    end

    def change(option, value)
      if @options[option] != value
        @options[option] = value.freeze
        @notify.config_changed(option) if @notify.respond_to? :config_changed
      end
      self
    end
  end
end
