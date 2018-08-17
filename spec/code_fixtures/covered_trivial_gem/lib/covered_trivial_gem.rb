require_relative "covered_trivial_gem/version"

module CoveredTrivialGem
  def self.hello
    'hello' && :world
  end

  def self.branches(used = 42, unused = 666)
    if true
      42
    end
    if false
      42
    end
    (1..2).each do |i|
      if i == 1
        42
      else
        43
      end
    end
    if false
    else
    end
    raise "booh!" if false
    blocks if true
    42 ? 1 : 2
  end

  def self.blocks
    0.times do
    end
    1.times do |x = 42|
      42
    end
  end

  def uncovered
    42
  end

  def also_uncovered
  end
end
