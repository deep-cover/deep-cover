# frozen_string_literal: true

require_relative '../deep_cover'
require_relative 'coverage'
require_relative 'core_ext/coverage_replacement'

require 'coverage'
BuiltinCoverage = Coverage
Object.send(:remove_const, 'Coverage')
Coverage = DeepCover::CoverageReplacement.dup
DeepCover::TAKEOVER_IS_ON = true
