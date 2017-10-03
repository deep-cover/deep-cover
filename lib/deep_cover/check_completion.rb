require_relative 'executed_after_children'

module DeepCover
  module CheckCompletion
    def check_completion(outer:'(%{node})', inner:'(%{node})')
      has_tracker :completion
      include ExecutedAfterChildren
      alias_method :flow_completion_count, :completion_tracker_hits
      pre, post = outer.split('%{node}')
      define_method(:rewrite) { "#{pre}#{inner}.tap{%{completion_tracker}}#{post}" }
    end
  end
end
