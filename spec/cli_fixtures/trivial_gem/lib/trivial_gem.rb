require_relative "trivial_gem/version"

module TrivialGem
  def self.hello
    'hello' && :world
  end

  def uncovered
    42
  end
end
