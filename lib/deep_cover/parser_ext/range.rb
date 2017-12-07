# frozen_string_literal: true

class Parser::Source::Range
  # (1...10).split(2...3, 6...8) => [1...2, 3...6, 7...10]
  # Assumes inner_ranges are exclusive, and included in self
  def split(*inner_ranges)
    inner_ranges.sort_by!(&:begin_pos)
    [self.begin, *inner_ranges, self.end]
      .each_cons(2)
      .map { |i, j| with(begin_pos: i.end_pos, end_pos: j.begin_pos) }
      .reject(&:empty?)
  end

  def lstrip(pattern = /\s*/)
    if (match = /^#{pattern}/.match(source))
      with(begin_pos: @begin_pos + match[0].length)
    else
      self
    end
  end

  def rstrip(pattern = /\s*/)
    if (match = /#{pattern}$/.match(source))
      with(end_pos: @end_pos - match[0].length)
    else
      self
    end
  end

  def strip(pattern = /\s*/)
    lstrip(pattern).rstrip(pattern)
  end

  def succ
    adjust(begin_pos: +1, end_pos: +1)
  end
end
