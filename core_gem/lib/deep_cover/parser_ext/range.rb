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

  # Only wraps anything if there is a comment to wrap on the last line
  # Will wrap the whitespace before the comment
  def wrap_final_comment
    current = wrap_rwhitespace(whitespaces: /\A[ \t\r\f]+/)
    if @source_buffer.slice(current.end_pos) != '#'
      # No comment, do nothing
      return self
    end
    comment = @source_buffer.slice(current.end_pos..-1)[/\A[^\n]+/] || ''
    current.adjust(end_pos: comment.size)
  end
end
