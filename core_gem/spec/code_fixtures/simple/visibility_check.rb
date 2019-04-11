# From backports
EXCLUDE = []
def class_signature(klass)
  list =
    (klass.instance_methods - EXCLUDE).map{|m| [m, klass.instance_method(m)] } +
    (klass.methods - EXCLUDE).map{|m| [".#{m}", klass.method(m) ]}
  list.select!{|name, method| method.source_location } if UnboundMethod.method_defined? :source_location
  Hash[list]
end

all_modules = ObjectSpace.each_object(Module).to_a

def module_signature(mod)
  %i[public protected private].flat_map do |what|
    mod.send(:"#{what}_instance_methods", false).map do |method|
      "#{what} #{mod}##{method}"
    end
  end
end

before = all_modules.flat_map { |mod| module_signature(mod) }

require_relative '../../../lib/deep-cover'
DeepCover.start

after = all_modules.flat_map { |mod| module_signature(mod) }

removed = before - after
removed -= ['private Module#define_method'] # Via backports
unless removed.empty?
  puts "Before:", removed
  err = true
end

added = after - before
added.select! {|line| line =~ /public Kernel/}
added -= ['public Kernel#yield_self'] # Via backports
unless added.empty?
  puts "After:", added
  err = true
end

exit(1) if err
puts "ok"

