# frozen_string_literal: true

module DeepCover
  module Coverage::Istanbul
    def to_istanbul(**options)
      map do |covered_code|
        [covered_code.name, Reporter::Istanbul.new(covered_code, **options).convert]
      end.to_h
    end

    def output_istanbul(dir: '.', name: '.nyc_output', **options)
      path = Pathname.new(dir).expand_path.join(name)
      path.mkpath
      path.each_child(&:delete)
      path.join('deep_cover.json').write(JSON.pretty_generate(to_istanbul(**options)))
      path
    end

    def report_istanbul(output: nil, **options)
      dir = output_istanbul(**options).dirname
      unless [nil, false, '', 'false'].include? output
        output = File.expand_path(output)
        html = "--reporter=html --report-dir='#{output}'"
        if options[:open]
          html += " && open '#{output}/index.html'"
        else
          msg = "\nHTML coverage written to: '#{output}/index.html'"
        end
      end
      `cd #{dir} && nyc report --reporter=text #{html}` + msg.to_s
    end
  end
end
