# frozen_string_literal: true

module DeepCover
  Reporter::HTML = Module.new

  require_relative_dir 'html'
end
