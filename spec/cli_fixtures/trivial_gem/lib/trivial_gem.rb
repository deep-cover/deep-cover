require "trivial_gem/version"

module TrivialGem
  def self.hello
    :world
  end

  def uncovered
    42
  end
end
