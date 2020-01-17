# frozen_string_literal: true

module DeepCover
  class Config
    NOT_SPECIFIED = Object.new

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

    def to_hash_for_serialize
      hash = to_hash
      # TODO: (Max) I don't like mixup of configs being partly on DeepCover and Config like that...
      hash[:paths] = DeepCover.lookup_globs
      hash[:output] = hash[:output] ? File.expand_path(hash[:output]) : hash[:output]
      hash[:cache_directory] = File.expand_path(hash[:cache_directory])
      hash
    end

    def load_hash_for_serialize(hash)
      @options.merge!(hash)
      hash.each_key { |option| @notify.config_changed(option) } if @notify
      # This was already transformed, it should all be absolute paths / globs, avoid doing it for nothing by setting it right away
      # TODO: (Max) I don't like mixup of configs being partly on DeepCover and Config like that...
      DeepCover.instance_variable_set(:@lookup_globs, hash[:paths])
    end

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

    def paths(paths = NOT_SPECIFIED)
      return @options[:paths] if paths == NOT_SPECIFIED

      change(:paths, Array(paths).dup)
    end

    def tracker_global(tracker_global = NOT_SPECIFIED)
      return @options[:tracker_global] if tracker_global == NOT_SPECIFIED

      change(:tracker_global, tracker_global)
    end

    def reporter(reporter = NOT_SPECIFIED)
      return @options[:reporter] if reporter == NOT_SPECIFIED

      change(:reporter, reporter)
    end

    def output(path_or_false = NOT_SPECIFIED)
      return @options[:output] if path_or_false == NOT_SPECIFIED

      change(:output, path_or_false)
    end

    def cache_directory(cache_directory = NOT_SPECIFIED)
      return File.expand_path(@options[:cache_directory]) if cache_directory == NOT_SPECIFIED

      change(:cache_directory, cache_directory)
    end

    def allow_partial(allow_partial = NOT_SPECIFIED)
      return @options[:allow_partial] if allow_partial == NOT_SPECIFIED

      change(:allow_partial, allow_partial)
    end

    def reset
      DEFAULTS.each do |key, value|
        change(key, value)
      end
      self
    end

    def [](opt)
      public_send(opt)
    end

    def []=(opt, value)
      public_send(opt, value)
    end

    def set(**options)
      @options[:ignore_uncovered] = [] if options.has_key?(:ignore_uncovered)
      options.each do |key, value|
        self[key] = value
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
