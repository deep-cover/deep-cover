# frozen_string_literal: true

module DeepCover
  require_relative 'covered_code'
  Coverage = Class.new
  require_relative_dir 'coverage'
  Coverage.include Coverage::Istanbul
end
