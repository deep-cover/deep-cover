# frozen_string_literal: true

class Parser::Source::Range
  def succ
    adjust(begin_pos: +1, end_pos: +1)
  end

  def wrap_rwhitespace(whitespaces: /\A\s+/)
    whitespace = @source_buffer.slice(end_pos..-1)[whitespaces] || ''
    adjust(end_pos: whitespace.size)
  end

  def wrap_rwhitespace_and_comments(whitespaces: /\A\s+/)
    current = wrap_rwhitespace(whitespaces: whitespaces)
    while @source_buffer.slice(current.end_pos) == '#'
      comment = @source_buffer.slice(current.end_pos..-1)[/\A[^\n]+/] || ''
      current = current.adjust(end_pos: comment.size).wrap_rwhitespace(whitespaces: whitespaces)
    end
    current
  end
end
