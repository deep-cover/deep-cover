module DeepCover
  class Node < Parser::AST::Node
  end
end

require_relative 'node/cover_entry'
require_relative 'node/cover_entry_and_exit'
require_relative_dir 'node'

module DeepCover
  class Node < Parser::AST::Node
    attr_reader :context, :nb

    def self.factory(type)
      class_name = type.capitalize
      const_defined?(class_name) ? const_get(class_name) : self
    end

    def assign_properties(properties = {})
      @context = properties.fetch(:context)
      @nb = properties.fetch(:nb)
      super
    end

    def proper_range
      location.expression.to_a - children.flat_map{|n| n.respond_to?(:location) && n.location && n.location.expression.to_a }
    end

    def was_called?
      false
    end

    def callable?
      true
    end

    def runs
      0
    end

    def changed_control_flow?
      children.any? do |child|
        child.is_a?(Node) && child.changed_control_flow?
      end
    end

    def prefix
    end

    def suffix
    end
  end
end
