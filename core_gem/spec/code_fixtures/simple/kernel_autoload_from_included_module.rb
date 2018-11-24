# frozen_string_literal: true
$executed_files << File.basename(__FILE__)

if RUBY_PLATFORM == 'java'
  # Yeah, this is weird
  # https://github.com/jruby/jruby/issues/5466
  class Object
    class << self
      module KernelAutoloadFromIncludedModule
      end
    end
  end
else
  module TheParentModule
    module KernelAutoloadFromIncludedModule
    end
  end
end
