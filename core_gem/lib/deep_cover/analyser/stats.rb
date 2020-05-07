# frozen_string_literal: true

module DeepCover
  class Analyser::StatsBase
    DECIMALS = 2
    include Memoize
    memoize :to_h, :total

    VALUES = %i[executed not_executed not_executable ignored].freeze # All are exclusive

    attr_reader(*VALUES)

    def to_h
      VALUES.map { |val| [val, public_send(val)] }.to_h
    end

    def initialize(executed: 0, not_executed: 0, not_executable: 0, ignored: 0)
      @executed = executed
      @not_executed = not_executed
      @not_executable = not_executable
      @ignored = ignored
      freeze
    end

    def +(other)
      self.class.new(**to_h.merge(other.to_h) { |k, a, b| a + b })
    end

    def total
      to_h.values.inject(:+)
    end

    def with(**values)
      self.class.new(**to_h.merge(values))
    end

    def potentially_executable
      total - not_executable
    end

    def percent_covered
      return 100 if potentially_executable == 0
      (100 * (1 - not_executed.fdiv(potentially_executable))).round(DECIMALS)
    end
  end

  class Analyser::Stats < Analyser::StatsBase
    memoize :percent

    def percent
      Analyser::StatsBase.new(**to_h.transform_values { |v| (100 * v).fdiv(total).round(DECIMALS) })
    end
  end
end
