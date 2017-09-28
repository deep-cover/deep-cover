class RSpec::Core::ExampleGroup
  def self.each_code_examples(glob, &block)
    Dir.glob(glob).each do |fn|
      describe File.basename(fn, '.rb') do
        example_groups = DeepCover::Tools::AnnotatedExamplesParser.process(File.read(fn).lines)
        example_groups.each do |section, examples|
          context(section || '(General)') do
            examples.each do |title, (lines, lineno)|
              msg = case [section, title].join
                    when /\(pending/i then :pending
                    when /\(Ruby 2\.(\d)/i
                      :skip if RUBY_VERSION < "2.#{$1}.0"
                    end
              send(msg || :it, title || '(General)') { self.instance_exec(fn, lines, lineno, &block) }
            end
          end
        end
      end
    end
  end
end
