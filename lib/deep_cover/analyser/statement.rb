module DeepCover
  class Analyser::Statement
    attr_reader :node_runs

    def initialize(node_runs: nil, covered_code: (raise unless node_runs), **options)
      @node_runs = node_runs || Analyser::Node.new(covered_code, **options).results
      @ast = @node_runs.first.first.covered_code.covered_ast
    end

    # Returns a map of Range => runs
    def results
      each_statement(@ast).flat_map do |node, sub_statements|
        shatter(node, sub_statements).map{|r| [r, @node_runs[node]]}
      end.to_h
    end

    private

    # returns a list of [proper_range, node], where
    # the nodes may be repeating, the proper_ranges are non-intersecting but non ordered.
    def shatter(node, sub_statements)
      subs = sub_statements.map{|n| n.loc_hash[:expression]}.compact
      range = node.loc_hash[:expression]
      subs.reject!{|r| r.disjoint?(range) } # This is the case iff using heredocs
      proper = range.split(*subs)
      proper.map!{|r| r.lstrip(/(\s*#.*\n)+/) }  # Strip comment blocks
      proper.map!{|r| r.strip(/[^a-zA-Z0-9'"\[\]{}_:$]*/) } # Ignore whitespace & punctuation
      proper.reject!(&:empty?)
      proper.reject!{|r| r.source == 'end' || r.source == '}'}
      proper
    end

    # Produce a simplified AST such that the nodes are either statements,
    # or sub-statements with execution incompatible with their enclosing {sub-}statement.
    STATEMENTS = Set[Node::Def, Node::Defs, Node::Module, Node::Class, Node::Sclass]
    STATEMENT_GROUPINGS = Set[Node::Begin, Node::Kwbegin, Node::Root]
    # Returns an array of children
    def each_statement(node, parent_statement_node = node.parent, &block)
      return to_enum(:each_statement, node, parent_statement_node) unless block_given?
      keep = if node.loc_hash[:expression].nil?
        false
      elsif node.is_statement
        true
      else
        !compatible_runs?(@node_runs[parent_statement_node], @node_runs[node])
      end

      process_subs = ->(parent) do
        node.children_nodes.flat_map do |c|
          each_statement(c, parent, &block)
        end
      end

      if keep
        s = process_subs[node]
        yield node, s
        [node]
      else
        process_subs[parent_statement_node]
      end
    end

    def compatible_runs?(expression_runs, sub_expression_runs)
      sub_expression_runs.nil? ||
        (sub_expression_runs == 0) == (expression_runs == 0)
    end
  end
end
