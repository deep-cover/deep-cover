# frozen_string_literal: true

module DeepCover
  class Config
    NOT_SPECIFIED = Object.new

    def initialize(notify = nil)
      @notify = nil
      @options = {}
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
        AttributeAccessors.define_accessor(FILTER_NAME[keywords.first])
      end
      unless keywords.empty?
        keywords = check_uncovered(keywords)
        set(**keywords.to_h { |kind| [FILTER_NAME[kind], true] })
      end
      Config.options_to_ignored(**@options)
    end

    def detect_uncovered(*keywords)
      raise ArgumentError, 'No block is accepted' if block_given?
      unless keywords.empty?
        keywords = check_uncovered(keywords)
        set(keywords.to_h { |kind| [FILTER_NAME[kind], false] })
      end
      OPTIONALLY_COVERED - Config.options_to_ignored(**@options)
    end

    module AttributeAccessors
      def self.define_accessor(attr)
        define_method(attr) do |arg = NOT_SPECIFIED|
          return @options[attr] if arg == NOT_SPECIFIED

          change(attr, arg)
        end
      end

      %i[paths tracker_global reporter output cache_directory allow_partial]
        .concat(OPTIONALLY_COVERED.map { |filter| FILTER_NAME[filter] })
        .each { |attr| define_accessor(attr) }
    end

    include AttributeAccessors

    def paths(paths = NOT_SPECIFIED)
      paths = Array(paths).dup unless paths == NOT_SPECIFIED
      super
    end

    def cache_directory(cache_directory = NOT_SPECIFIED)
      return File.expand_path(super) if cache_directory == NOT_SPECIFIED
      super
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
      options.each do |key, value|
        self[key] = value
      end
      self
    end

    def self.options_to_ignored(**options)
      OPTIONALLY_COVERED
        .select { |filter| options[FILTER_NAME[filter]] }
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
