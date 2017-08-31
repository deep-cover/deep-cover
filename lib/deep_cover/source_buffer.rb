module DeepCover
  class SourceBuffer < ::Parser::Source::Buffer
    attr_accessor :ast, :covered_source, :node_list
    @@counter = 0

    def initialize(*)
      super
      @node_list = []
    end

    # Returns the node's number
    def register_node(node)
      @node_list.push(node)
      @node_list.size - 1
    end

    def cover
      return @cover if @cover
      $_cov ||= {}
      $_cov[nb] = @cover = Array.new(@node_list.size * 2, 0)
      eval(covered_source)
      @cover
    end

    def coverage
      cover
      hits = Array.new(covered_source.lines.size)
      @node_list.each do |node|
        ln = node.loc.expression.line - 1
        hits[ln] ||= 0
        hits[ln] = [hits[ln], node.entry_runs].max
      end
      hits
    end

    def branch_cover
      cover = source_lines.map{|line| ' ' * line.size}
      @node_list.each do |node|
        unless node.was_called?
          bad = node.proper_range
          bad.each do |pos|
            cover[line_for_position(pos)-1][column_for_position(pos)] = 'x'
          end
        end
      end
      cover
    end

    def nb
      @nb ||= (@@counter += 1)
    end
  end
end
