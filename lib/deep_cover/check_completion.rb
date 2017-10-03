require_relative 'executed_after_children'

module DeepCover
  module CheckCompletion
    def check_completion(wrap='((%{node}))')
      has_tracker :completion
      include ExecutedAfterChildren
      alias_method :flow_completion_count, :completion_tracker_hits
      define_method(:rewrite) { "#{wrap}.tap{%{completion_tracker}}"}
    end
  end
end
