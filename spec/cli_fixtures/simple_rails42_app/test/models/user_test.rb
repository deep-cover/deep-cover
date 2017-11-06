require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def test_hello
    u = User.new(name: 'hi')

    assert u.save!
  end

  def test_foo
    u = User.new(name: 'hi')

    assert_equal 42, u.foo
  end

  def test_hello
    u = User.new(name: 'hi')

    assert_equal 42, u.baz
  end
end
