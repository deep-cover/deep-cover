# frozen_string_literal: true

module DeepCover
  module Reporter::HTML::Base
    include Tools::ContentTag
    def setup
      DeepCover::DEFAULTS.keys.map do |setting|
        value = options[setting]
        value = value.join(', ') if value.respond_to? :join
        content_tag :span, value, class: setting
      end.join
    end
  end
end
