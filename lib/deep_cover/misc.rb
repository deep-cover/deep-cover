class Module
  public :prepend, :include # Are public in Ruby 2.1+.
end

module DeepCover
  module Misc
    extend self

    # Poor man's camelize. 'an_example' => 'AnExample'
    def camelize(string)
      string.to_s.gsub(/([a-z\d]*)[_?!]?/){ $1.capitalize }
    end
  end
end
