# frozen_string_literal: true

class Parser::Source::Range
  def succ
    adjust(begin_pos: +1, end_pos: +1)
  end

  def wrap_rwhitespace
    whitespace = @source_buffer.slice(end_pos..-1)[/\A\s+/] || ''
    adjust(end_pos: whitespace.size)
  end
end
