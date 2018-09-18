# frozen_string_literal: true

module DeepCover
  module Tools::OurCoverage
    def our_coverage(source, filename, lineno, **options)
      covered_code = CoveredCode.new(source: source, path: filename, lineno: lineno)
      Tools.execute_sample(covered_code)
      covered_code.line_coverage(**options)[(lineno - 1)..-1]
    end
  end
end
