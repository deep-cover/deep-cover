# frozen_string_literal: true

module DeepCover
  module Tools::Dasherize
    # Poor man's dasherize. 'an_example' => 'an-example'
    def dasherize(string)
      string.to_s.gsub('_', '-')
    end
  end
end
