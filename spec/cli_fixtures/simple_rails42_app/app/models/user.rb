require 'dummy'

class User < ApplicationRecord
  include Dummy
  def foo
    42
  end
  def bar
    42
  end
end
