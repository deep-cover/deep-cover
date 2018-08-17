require "another_component_gem/foo"

module AnotherComponentGem
  extend AnotherComponentGem::Foo

  def not_covered
    666
  end
end
