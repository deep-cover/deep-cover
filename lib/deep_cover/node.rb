require_relative 'node/base'
require_relative_dir 'node_behavior'
require_relative_dir 'node'

module DeepCover
  Node.constants.each do |name|
    klass = Node.const_get(name)
    if klass.is_a?(Class) && klass < Node
      if klass.const_defined?(:CHILDREN)
        if klass <  NodeBehavior::CoverWithNextInstruction
          indices = klass::CHILDREN.values
          if indices.size > 1 || indices[0].is_a?(Range)
            warn "Class #{klass} has many children but is using CoverWithNextInstruction"
          end
        end
        if klass.instance_method(:full_runs).owner == Node
          warn "Class #{klass} has children but has not refined full_runs"
        end
      end
    end
  end
end
