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
    self.peek
  end

  def self.peek
    results = DeepCover.coverage.covered_codes.map do |filename, covered_code|
      [filename, covered_code.line_coverage(allow_partial: false)]
    end
    Hash[results]
  end
end
