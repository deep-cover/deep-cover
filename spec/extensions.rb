# frozen_string_literal: true

class RSpec::Core::ExampleGroup
  def self.each_code_examples(glob, max_files: nil, name: 'unnamed', &block)
    Dir.glob(glob).sort.each_with_index do |fn, i|
      break if max_files && i >= max_files

      index = 0
      spec = File.basename(fn, '.rb')
      describe spec do
        example_groups = DeepCover::Specs::AnnotatedExamplesParser.process(File.read(fn).lines)
        example_groups.each do |section, examples|
          context(section || '(General)') do
            examples.each do |title, (lines, lineno)|
              msg = case [section, title].join
                    when /\(pending/i then :pending
                    when /\(skip/i then next
                    when /\(#{name}_pending/i then :pending
                    when /\(Ruby 2\.(\d)\+/i
                      :skip if RUBY_VERSION < "2.#{Regexp.last_match(1)}.0"
                    when /\(Ruby 2\.(\d)\-/i
                      :skip if RUBY_VERSION > "2.#{Regexp.last_match(1)}.0"
                    when /\(!Jruby/i
                      :skip if RUBY_PLATFORM == 'java'
                    end
              if [section, title].join =~ /\(tag: (\w+)/
                tag = Regexp.last_match(1).to_sym
              end
              send(msg || :it, "#{title || '(General)'} [#{spec} #{index}]", *tag) { self.instance_exec(fn, lines, lineno, &block) }
              index += 1
            end
          end
        end
      end
    end
  end
end
