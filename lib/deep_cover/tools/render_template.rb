# frozen_string_literal: true

module DeepCover
  module Tools::RenderTemplate
    def render_template(template, bound_object)
      require 'erb'
      caller_path = Pathname.new(caller(1..1).first.partition(/\.rb:\d/).first).dirname
      template = caller_path.join("template/#{template}.html.erb").read
      erb = ERB.new(template)
      erb.result(bound_object.instance_eval { binding })
    end
  end
end
