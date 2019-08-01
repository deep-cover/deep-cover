# frozen_string_literal: true

module DeepCover
  module Tools::StripHeredoc
    # In-place implementation copied from active-support.
    IMPLEMENTATION = -> do
      gsub(/^#{scan(/^[ \t]*(?=\S)/).min}/, '').tap do |stripped|
        stripped.freeze if frozen?
      end
    end

    # Same as #strip_heredoc from active-support
    # https://github.com/rails/rails/blob/16574409f813e2197f88e4a06b527618d64d9ff0/activesupport/lib/active_support/core_ext/string/strip.rb#L22
    def strip_heredoc(string)
      string.instance_exec(&IMPLEMENTATION)
    end
  end
end
