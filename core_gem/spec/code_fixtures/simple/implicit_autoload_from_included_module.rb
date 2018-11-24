# frozen_string_literal: true
$executed_files << File.basename(__FILE__)

if RUBY_PLATFORM == 'java'
  class TheParentClass
    module ImplicitAutoloadFromIncludedModule
    end
  end
else
  module TheParentModule
    module ImplicitAutoloadFromIncludedModule
    end
  end
end
