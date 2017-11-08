module DeepCover
  class Node
    # Reopened in base
    CLASSES = []
    def self.inherited(parent)
      CLASSES << parent
      super
    end
  end
  require_relative_dir 'node/mixin'
  require_relative 'node/base'
  require_relative_dir 'node'
end
