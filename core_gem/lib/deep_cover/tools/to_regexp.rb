# frozen_string_literal: true

module DeepCover
  module Tools::ToRegexp
    def to_regexp(regexp_or_str)
      case regexp_or_str
      when Regexp
        regexp_or_str
      when String
        Regexp.new(Regexp.quote(regexp_or_str))
      else
        raise TypeError
      end
    end
  end
end
