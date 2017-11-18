# frozen_string_literal: true

# This is a complete replacement for the builtin Coverage module of Ruby

require 'coverage'
BuiltinCoverage = Coverage
Object.send(:remove_const, 'Coverage')

module Coverage
  def self.start
    @started = true
    DeepCover.start
    DeepCover.coverage.reset
  end

  def self.result
    raise 'coverage measurement is not enabled' unless @started
    @started = false
    peek_result
  end

  def self.peek_result
    results = DeepCover.coverage.covered_codes.map do |covered_code|
      [covered_code.path, covered_code.line_coverage(allow_partial: false)]
    end
    Hash[results]
  end
end
