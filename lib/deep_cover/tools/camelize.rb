# frozen_string_literal: true

module DeepCover
  module Tools::Camelize
    # Poor man's camelize. 'an_example' => 'AnExample'
    def camelize(string)
      string.to_s.gsub(/([a-z\d]*)[_?!]?/) { Regexp.last_match(1).capitalize }
    end
  end
end
