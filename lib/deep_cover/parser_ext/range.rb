# frozen_string_literal: true

class Parser::Source::Range
  def succ
    adjust(begin_pos: +1, end_pos: +1)
  end
end
