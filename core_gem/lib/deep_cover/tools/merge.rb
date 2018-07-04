# frozen_string_literal: true

module DeepCover
  module Tools::Merge
    def merge(*hashes)
      if hashes.last.is_a?(Symbol)
        oper = hashes.pop
        merge(*hashes) { |a, b| a.public_send(oper, b) }
      elsif !block_given?
        merge(*hashes, &:last)
      else
        hashes.inject { |result, h| result.merge(h) { |key, a, b| yield [a, b] } }
      end
    end
  end
end
