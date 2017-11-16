# frozen_string_literal: true

module DeepCover
  class Coverage::Analysis < Struct.new(:covered_codes, :options)
    include Memoize
    memoize :analyser_map, :stat_map

    def analyser_map
      covered_codes.map do |covered_code|
        [covered_code, compute_analysers(covered_code)]
      end.to_h
    end

    def stat_map
      analyser_map.transform_values { |a| a.transform_values(&:stats) }
    end

    private

    def compute_analysers(covered_code)
      base = Analyser::Node.new(covered_code, **options)
      {node: base}.merge!(
          {
            per_char: Analyser::PerChar,
            branch: Analyser::Branch,
          }.transform_values { |klass| klass.new(base, **options) }
      )
    end
  end

  class Coverage
    def analysis(**options)
      Analysis.new(covered_codes, options)
    end
  end
end
