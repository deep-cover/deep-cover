# frozen_string_literal: true
module DeepCover
  module Tools::FormatCharCover
    COLOR = {'x' => :red, ' ' => :green, '-' => :faint}
    WHITESPACE_MAP = Hash.new{|_, v| v}.merge!(' ' => '·', "\t" => '→ ')
    def format_char_cover(covered_code, show_whitespace: false, **options)
      bc = covered_code.char_cover(**options)
      covered_code.buffer.source_lines.map.with_index do |line, line_index|
        next line if line.strip =~ /^#[ >]/
        line.chars.map.with_index do |c, c_index|
          color = COLOR[bc[line_index][c_index]]
          c = WHITESPACE_MAP[c] if show_whitespace
          Term::ANSIColor.send(color, c)
        end.join
      end
    end
  end
end
