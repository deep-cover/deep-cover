# frozen_string_literal: true

module DeepCover
  ##
  # A processor which computes which lines to be considered flagged with the
  # given lookup
  #
  class FlagCommentAssociator
    ##
    # @param [DeepCover::RootNode] ast
    # @param [Array(Parser::Source::Comment)] comments
    def initialize(covered_code, lookup = 'nocov')
      @covered_code = covered_code
      @lookup      = /^#[\s#*-]*#{lookup}[\s#*-]*$/
      @ranges      = nil
    end

    def include?(range)
      return false unless (exp = range.expression)
      lineno = exp.line
      ranges.any? { |r| r.cover? lineno }
    end

    def ranges
      @ranges ||= compute_ranges
    end

    private

    def compute_ranges
      @ranges     = []
      @flag_start = nil
      index_ast_lines
      @covered_code.comments.each { |comment| process(comment) }
      toggle_flag(@covered_code.buffer.last_line) # handle end of file in case of opened flag
      @ranges
    end

    def process(comment)
      return unless comment.text =~ @lookup
      ln = comment.location.expression.line
      toggle_flag(ln) unless line_has_only_comments?(ln)
      toggle_flag(ln + 1)
    end

    def toggle_flag(lineno)
      if @flag_start
        @ranges << (@flag_start..(lineno - 1))
        @flag_start = nil
      else
        @flag_start = lineno
      end
    end

    def index_ast_lines
      @starts = []
      @covered_code.each_node do |node|
        if (exp = node.expression)
          @starts[exp.line] = true
        end
      end
    end

    def line_has_only_comments?(line)
      !@starts[line]
    end
  end
end
