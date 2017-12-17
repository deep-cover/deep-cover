# frozen_string_literal: true

module DeepCover
  require_relative 'base'

  module Reporter
    class HTML::Index < Struct.new(:analysis, :options)
      def initialize(analysis, **options)
        raise ArgumentError unless analysis.is_a? Coverage::Analysis
        super
      end

      include Util::Tree
      include HTML::Base

      def stats_to_data
        @map = Tools.transform_keys(analysis.stat_map, &:name)
        tree = paths_to_tree(@map.keys)
        data = tree_to_data(tree)
        transform_data(data)
      end

      def columns
        _covered_code, analyser_map = analysis.analyser_map.first
        columns = analyser_map.flat_map do |type, analyser|
          [{
             value: type,
             header: analyser.class.human_name,
           }, {
                value: :"#{type}_percent",
                header: '%',
              },
          ]
        end
        columns.unshift(width: 400, header: 'Path')
        columns
      end

      private

      # {a: {}}    => [{text: a, data: stat_map[a]}]
      # {b: {...}} => [{text: b, data: sum(stats), children: [...]}]
      def tree_to_data(tree)
        populate(tree) do |full_path, partial_path, children|
          if children.empty?
            {
              text: %{<a href="#{full_path}.html">#{partial_path}</a>},
              data: @map[full_path],
            }
          else
            children_data = Tools.merge(*children.map { |c| c[:data] }, :+)
            {
              text: partial_path,
              data: children_data,
              children: children,
              state: {opened: true},
            }
          end
        end
      end

      # Modifies in place the tree:
      # {per_char: Stat, ...} => {per_char: {ignored: ...}, per_char_percent: 55.55, ...}
      def transform_data(tree)
        return unless tree
        tree.each do |node|
          node[:data] = Tools.merge(
              node[:data].transform_values(&:to_h),
              *node[:data].map { |type, stat| {:"#{type}_percent" => stat.percent_covered} }
          )
          transform_data(node[:children])
        end
      end
    end
  end
end
