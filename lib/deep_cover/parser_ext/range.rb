# frozen_string_literal: true

class Parser::Source::Range
  def succ
    adjust(begin_pos: +1, end_pos: +1)
  end

  def wrap_rwhitespace
    whitespace = @source_buffer.slice(end_pos..-1)[/\A\s+/] || ''
    adjust(end_pos: whitespace.size)
  end

  def wrap_rwhitespace_and_comments
    current = wrap_rwhitespace
    while @source_buffer.slice(current.end_pos) == '#'
      comment = @source_buffer.slice(current.end_pos..-1)[/\A[^\n]+/] || ''
      current = current.adjust(end_pos: comment.size).wrap_rwhitespace
    end
    current
  end
end
