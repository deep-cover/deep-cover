class Parser::AST::Node
  # AST::Node insists on freezing itself.
  # It's inconvenient.
  def freeze
    self
  end

  def nb
    @nb ||= buffer.register_node(self)
  end

  def proper_range
    location.expression.to_a - children.flat_map{|n| n.respond_to?(:location) && n.location && n.location.expression.to_a }
  end

  def was_called?
    case type
    when :send
      receiver, method, *args = children
      ran_exit? || args.compact.all?(&:ran_exit?)
    else
      ran_entry?
    end
  end

  def ran_entry?
    entry_runs > 0
  end

  def ran_exit?
    exit_runs > 0
  end

  def entry_runs
    @nb ? buffer.cover.fetch(2 * nb) : 0
  end

  def exit_runs
    @nb ? buffer.cover.fetch(2 * nb + 1) : 0
  end

  def buffer
    binding.pry unless location.expression
    location.expression.source_buffer
  end
end
