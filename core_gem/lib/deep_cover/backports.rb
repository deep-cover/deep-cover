# frozen_string_literal: true

# We use a few features newer than our target of Ruby 2.1+:
class Module
  public :define_method
end
require 'pathname'
class Pathname
  def write(*args)
    File.write(to_path, *args)
  end unless method_defined? :write
  def binwrite(*args)
    File.binwrite(to_path, *args)
  end unless method_defined? :binwrite
end # nocov
require 'backports/2.4.0/false_class/dup'
require 'backports/2.4.0/true_class/dup'
require 'backports/2.4.0/hash/transform_values'
require 'backports/2.4.0/enumerable/sum'
require 'backports/2.4.0/regexp/match'
require 'backports/2.5.0/hash/slice'
require 'backports/2.5.0/hash/transform_keys'
require 'backports/2.5.0/kernel/yield_self'
require 'backports/2.6.0/hash/to_h'
require 'backports/2.6.0/enumerable/to_h'
require 'backports/2.6.0/array/to_h'
