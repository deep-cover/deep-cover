# frozen_string_literal: true

module DeepCover
  module Tools::Blank
    BLANK_RE = /\A[[:space:]]*\z/

    # Homemade poor-man's blank?
    # Based, but modified, on https://github.com/rails/rails/blob/5-0-stable/activesupport/lib/active_support/core_ext/object/blank.rb
    def blank?(obj)
      if obj.is_a?(String)
        obj.empty? || obj =~ BLANK_RE
      else
        obj.respond_to?(:empty?) ? !!obj.empty? : !obj
      end
    end

    def present?(obj)
      !blank?(obj)
    end

    def presence(obj)
      obj if present?(obj)
    end
  end
end
