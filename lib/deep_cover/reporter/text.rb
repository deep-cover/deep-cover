# frozen_string_literal: true

module DeepCover
  require_relative 'base'

  module Reporter
    class Text < Base
      INDENT = '  '
      def report
        formatted_headings = headings.map.with_index { |h, i| {value: h, alignment: :center} }
        columns = rows.transpose
        (1...columns.size).step(2) { |i| columns[i] = formatted_stats(columns[i]) }
        table = Terminal::Table.new(
            headings: formatted_headings,
            rows: columns.transpose,
            style: {border_bottom: false, border_top: false, alignment: :right},
        )
        table.align_column 0, :left
        table.render + "\n\nOverall: #{analysis.overall}%"
      end

      def self.report(coverage, **options)
        Text.new(coverage, **options).report
      end

      private

      def formatted_stats(data)
        columns = data.transpose
        columns[1..1] = [] if columns[1].none?
        Terminal::Table.new(
            rows: columns.transpose,
            style: {border_x: '', border_bottom: false, border_top: false, alignment: :right}
        ).render.gsub(' | ', ' ').gsub(/ ?\| ?/, '').split("\n")
      end

      def rows
        Tree::Util.populate_stats(analysis).map do |full_path, partial_path, data, children|
          [partial_path, *transform_data(data)]
        end
      end

      def headings
        Coverage::Analysis.template.values.flat_map do |analyser|
          [analyser.human_name, '%']
        end.unshift('Path')
      end

      # {per_char: Stat, ...} => ['1 [+2] / 3', '100 %', ...]
      def transform_data(data)
        data.flat_map do |type, stat|
          ignored = "[+#{stat.ignored}]" if stat.ignored > 0
          [[stat.executed, ignored, '/', stat.potentially_executable], format('%.2f', stat.percent_covered)]
        end
      end
    end
  end
end
