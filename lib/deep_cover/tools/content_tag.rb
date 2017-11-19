# frozen_string_literal: true

module DeepCover
  module Tools::ContentTag
    # Poor man's content_tag. No HTML escaping included
    def content_tag(tag, content, **options)
      attrs = options.map { |kind, value| %{ #{kind}="#{value}"} }.join
      "<#{tag}#{attrs}>#{content}</#{tag}>"
    end
  end
end
