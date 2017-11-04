require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def test_hello
    u = User.new(name: 'hi')

    assert u.save!
  end
end
