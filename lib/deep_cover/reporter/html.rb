# frozen_string_literal: true

module DeepCover
  Reporter::HTML = Module.new

  require_relative_dir 'html'

  module Reporter::HTML
    class << self
      def report(coverage, **options)
        Site.save(coverage.covered_codes, **options)
      end
    end
  end
end
