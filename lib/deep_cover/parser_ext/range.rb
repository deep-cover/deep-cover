class Parser::Source::Range
  def with(begin_pos: @begin_pos, end_pos: @end_pos)
    Parser::Source::Range.new(@source_buffer, begin_pos, end_pos)
  end
end
