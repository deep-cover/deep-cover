# frozen_string_literal: true

module DeepCover
  module Tools::Covered
    def covered?(runs)
      runs && runs > 0
    end
  end
end
