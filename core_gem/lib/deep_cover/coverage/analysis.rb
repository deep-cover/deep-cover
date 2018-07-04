# frozen_string_literal: true

module DeepCover
  class Coverage
    class Analysis < Struct.new(:covered_codes, :options)
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

      def overall
        return 100 if stat_map.empty?
        node, branch = Tools.merge(*stat_map.values, :+).values_at(:node, :branch)
        (node + branch).percent_covered
      end

      def self.template
        {node: Analyser::Node, per_char: Analyser::PerChar, branch: Analyser::Branch}
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
  end
end
