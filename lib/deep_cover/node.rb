require_relative 'node/base'
require_relative_dir 'node_behavior'
require_relative_dir 'node'

module DeepCover
  Node.constants.each do |name|
    klass = Node.const_get(name)
    if klass < Node
      if klass.const_defined?(:CHILDREN) &&
          klass.instance_method(:full_runs).owner == Node
        warn "Class #{klass} has children but has not refined full_runs"
      end
    end
  end
end
