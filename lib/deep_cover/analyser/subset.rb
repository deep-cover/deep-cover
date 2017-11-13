# frozen_string_literal: true
module DeepCover
  # A module to create a subset from a criteria called `in_subset?`
  # Including classes can refine it, or specify SUBSET_CLASSES
  module Analyser::Subset
    def node_children(node)
      find_children(node)
    end

    private
    def find_children(from, parent = from)
      @source.node_children(from).flat_map do |node|
        if in_subset?(node, parent)
          [node]
        else
          find_children(node, parent)
        end
      end
    end

    def in_subset?(node, _parent)
      self.class::SUBSET_CLASSES.any?{|klass| node.is_a?(klass)}
    end
  end
end
