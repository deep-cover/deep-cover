# frozen_string_literal: true
module DeepCover
  module Tools::Format
    CONVERT = Hash.new('  ')
    CONVERT[0] = 'x '
    CONVERT[nil] = '- '

    def format(*results, filename: nil, source: nil)
      source ||= File.read(filename)
      results.map!{|counts| counts.map{|c| CONVERT[c]}}
      [*results, source.lines].transpose.map do |parts|
        *line_results, line = parts
        Term::ANSIColor.white(line_results.join) + line.to_s
      end
    end
  end
end
