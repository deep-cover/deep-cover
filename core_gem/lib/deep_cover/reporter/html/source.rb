# frozen_string_literal: true

module DeepCover
  module Reporter
    require_relative 'base'

    class HTML::Source < Struct.new(:analyser_map, :partial_path)
      include Tools::Covered

      def initialize(analyser_map, partial_path)
        raise ArgumentError unless analyser_map.values.all? { |a| a.is_a?(Analyser) }
        super
      end

      include HTML::Base

      def format_source
        lines = convert_source.split("\n")
        lines.map { |line| content_tag(:td, line) }
        rows = lines.map.with_index do |line, i|
          nb = content_tag(:td, i + 1, id: "L#{i + 1}", class: :nb)
          content_tag(:tr, nb + content_tag(:td, line))
        end
        content_tag(:table, rows.join, class: :source)
      end

      def convert_source
        @rewriter = Parser::Source::TreeRewriter.new(covered_code.buffer)
        insert_node_tags
        insert_branch_tags
        html_escape
        @rewriter.process
      end

      def root_path
        Pathname('.').relative_path_from(Pathname(partial_path).dirname)
      end

      def stats
        cells = analyser_map.map do |type, analyser|
          data = analyser.stats
          f = ->(kind) { content_tag(:span, data.public_send(kind), class: kind, title: kind) }
          [content_tag(:th, analyser.class.human_name, class: type),
           content_tag(:td, "#{f[:executed]} #{f[:ignored] if data.ignored > 0} / #{f[:potentially_executable]}", class: type),
          ]
        end
        rows = cells.transpose.map { |line| content_tag(:tr, line.join) }
        content_tag(:table, rows.join)
      end

      def analyser
        analyser_map[:per_char]
      end

      def covered_code
        analyser.covered_code
      end

      private

      RUNS_CLASS = Hash.new('run').merge!(0 => 'not-run', nil => 'ignored')
      RUNS_TITLE = Hash.new { |k, runs| "#{runs}x" }.merge!(0 => 'never run', nil => 'ignored')

      def node_span(node, kind)
        runs = analyser.node_runs(node)
        %{<span class="node-#{node.type} kind-#{kind} #{RUNS_CLASS[runs]}" title="#{RUNS_TITLE[runs]}">}
      end

      def insert_node_tags
        analyser.each_node do |node|
          h = node.executed_loc_hash
          h.each do |kind, range|
            wrap(range, node_span(node, kind), '</span>')
          end
          exp = node.expression
          if (exp.nil? || exp.empty?) && !analyser.node_covered?(node) && !node.parent.is_a?(Node::Branch) # Not executed empty bodies must show!
            replace(exp, icon(:empty, 'empty node never run'))
            wrap(exp, node_span(node, :empty))
          end
        end
      end

      ICONS = {
                fork: 'code-fork',
                empty: 'code',
              }.freeze
      def icon(type, title)
        %{<i class="#{type}-icon fa fa-#{ICONS[type]}" aria-hidden="true" title="#{title}"></i>}
      end

      def fork_span(node, kind, id, title: nil, klass: nil)
        runs = analyser_map[:branch].node_runs(node)
        title ||= RUNS_TITLE[runs]
        %{<span class="fork fork-#{kind} fork-#{RUNS_CLASS[runs]} #{klass}" data-fork-id="#{id}">#{icon(:fork, title)}}
      end

      def insert_branch_tags
        analyser_map[:branch].each_node.with_index do |node, id|
          node.branches.each do |branch|
            exp = branch.expression
            wrap(exp, fork_span(branch, :branch, id), '</span>') if exp
          end
          runs = analyser_map[:branch].node_runs(node)
          if !covered?(runs) && analyser.node_covered?(node)
            jumps_missing = node.branches.reject { |jump| analyser.node_covered?(jump) }
            title = "#{node.branches_summary(jumps_missing)} not covered"
            klass = 'fork-with-uncovered-branches'
          end
          wrap(node.expression, fork_span(node, :whole, id, title: title, klass: klass))
        end
      end

      def replace(range, with)
        @rewriter.replace(range, with)
      end

      def wrap(range, before, after = '</span>')
        line = @rewriter.source_buffer.line_range(range.first_line)
        pinned = range.with(end_pos: [range, line].map(&:end_pos).min)
        @rewriter.wrap(pinned, before, after)
      end

      def html_escape
        buffer = analyser.covered_code.buffer
        source = buffer.source
        {'<' => '&lt;', '>' => '&gt;', '&' => '&amp;'}.each do |char, escaped|
          source.scan(char) do
            m = Regexp.last_match
            range = Parser::Source::Range.new(buffer, m.begin(0), m.end(0))
            @rewriter.replace(range, escaped)
          end
        end
      end
    end
  end
end
