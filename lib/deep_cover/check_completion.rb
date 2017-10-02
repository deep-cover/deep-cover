module DeepCover
  module CheckCompletion
    def check_completion(wrap='((%{node}))')
      has_tracker :completion
      include InstanceMethods
      define_method(:rewrite) { "#{wrap}.tap{%{completion_tracker}}"}
    end

    module InstanceMethods
      def flow_completion_count
        completion_tracker_hits
      end

      def execution_count
        last = children_nodes_in_flow_order.last
        return last.flow_completion_count if last
        super
      end
    end
  end
end
