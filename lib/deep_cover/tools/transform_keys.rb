# frozen_string_literal: true

module DeepCover
  module Tools::TransformKeys
    def transform_keys(hash)
      hash.map { |key, value| [yield(key), value] }.to_h
    end
  end
end
