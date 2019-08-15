# frozen_string_literal: true

require_relative 'bar'

class Foo
  def bar(value = 42)
    if value >= 666
      raise "That's really big"
    end
    value * 2
  end
end
