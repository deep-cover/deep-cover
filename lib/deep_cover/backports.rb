# We use a few features newer than our target of Ruby 2.0+:
class Module
  public :prepend # Public in Ruby 2.1+.
end
require 'pathname'
class Pathname
  def write(*args)
    File.write(to_path, *args)
  end unless method_defined? :write
  def binwrite(*args)
    File.binwrite(to_path, *args)
  end unless method_defined? :binwrite
end
require 'backports/2.1.0/module/include'
require 'backports/2.1.0/enumerable/to_h'
require 'backports/2.4.0/false_class/dup'
require 'backports/2.4.0/true_class/dup'
require 'backports/2.4.0/hash/transform_values'
