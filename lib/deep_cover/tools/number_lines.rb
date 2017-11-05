module DeepCover
  module Tools::NumberLines
    def number_lines(lines, lineno: 1, bad_linenos: [])
      max_lineno = lineno + lines.size - 1
      nb_lineno_digits = max_lineno.to_s.size
      lines.map.with_index do |line, i|
        cur_lineno = lineno + i
        cur_lineno_s = cur_lineno.to_s.rjust(nb_lineno_digits)
        if bad_linenos.include?(cur_lineno)
          cur_lineno_s = "*#{cur_lineno_s}" unless bad_linenos.empty?
          prefix = Term::ANSIColor.red("#{cur_lineno_s} | ")
        else
          cur_lineno_s = " #{cur_lineno_s}" unless bad_linenos.empty?
          prefix = Term::ANSIColor.white("#{cur_lineno_s} | ")
        end
        "#{prefix}#{line}"
      end
    end
  end
end
