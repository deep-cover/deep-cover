# frozen_string_literal: true

module DeepCover
  bootstrap

  require_relative 'tracker_storage'

  # A holder for TrackerStorages, using some `global_name`.
  class TrackerBucket
    @@index = {}

    def self.[](global_name)
      raise ArgumentError, "'#{global_name}' is not a valid global name" unless global_name.start_with? '$'
      @@index[global_name] ||= new(global_name)
    end

    def setup_source
      "#{source} ||= {}"
    end

    def source
      @global_name
    end

    class << self
      alias_method :_load, :[]
      private :_load, :new
    end

    def inspect
      %{#<DeepCover::TrackerBucket "#{@global_name}">}
    end

    def create_storage(index = nil)
      index ||= @global.size
      TrackerStorage.new(bucket: self, array: @global[index] ||= [], index: index)
    end

    private

    def initialize(global_name)
      @global_name = global_name
      @global = eval(setup_source) # rubocop:disable Security/Eval
    end

    def _dump(_level)
      @global_name
    end
  end
end
