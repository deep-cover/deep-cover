# frozen_string_literal: true

module DeepCover
  bootstrap

  # A holder for TrackerLists, using some `global_name`.
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

    private

    def initialize(global_name)
      @global_name = global_name
      @global = eval(setup_source) # rubocop:disable Security/Eval
    end

    def _dump(_level)
      @global_name
    end

    # For use by TrackerList only
    def allocate_tracker_list(index = nil)
      index ||= @global.size
      [@global[index] ||= [], index]
    end
  end
end
