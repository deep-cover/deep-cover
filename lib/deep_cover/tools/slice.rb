# frozen_string_literal: true

module DeepCover
  module Tools::Slice
    def slice(hash, *keys)
      keys.each_with_object(Hash.new) { |k, h| h[k] = hash[k] if hash.has_key?(k) }
    end
  end
end
