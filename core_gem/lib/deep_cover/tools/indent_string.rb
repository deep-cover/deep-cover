# frozen_string_literal: true

module DeepCover
  module Tools::IndentString
    # In-place implementation copied from active-support.
    IMPLEMENTATION = ->(amount, indent_string = nil, indent_empty_lines = false) do
      indent_string = indent_string || self[/^[ \t]/] || ' '
      re = indent_empty_lines ? /^/ : /^(?!$)/
      gsub!(re, indent_string * amount)
    end

    # Same as #indent! from active-support
    # https://github.com/rails/rails/blob/10e1f1f9a129f2f197a44009a99b73b8ff9dbc0d/activesupport/lib/active_support/core_ext/string/indent.rb#L7
    def indent_string!(string, *args)
      string.instance_exec(*args, &IMPLEMENTATION)
    end

    # Same as #indent from active-support
    # https://github.com/rails/rails/blob/10e1f1f9a129f2f197a44009a99b73b8ff9dbc0d/activesupport/lib/active_support/core_ext/string/indent.rb#L42
    def indent_string(string, *args)
      string = string.dup
      indent_string!(string, *args)
      string
    end
  end
end
