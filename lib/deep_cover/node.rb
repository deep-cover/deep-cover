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
  end

  def buffer
    binding.pry unless location.expression
    location.expression.source_buffer
  end
end
