module DeepCover
  module NodeBehavior
    module CoverFromParent
      delegate :was_executed?, :runs, :executable?, to: :parent
    end
  end
end
