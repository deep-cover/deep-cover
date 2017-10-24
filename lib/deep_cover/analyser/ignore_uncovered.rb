module DeepCover
  module Analyser::IgnoreUncovered
    def initialize(source, ignore_uncovered: [], **options)
      super
      @allow_filters = Array(ignore_uncovered)
        .map{|kind| :"is_#{kind}?"}
        .select{|name| respond_to?(name) }
        .map{|name| method(name)}   # So was tempted to write `.map(&method(:method))`!
    end

    def node_runs(node)
      runs = super
      if runs == 0 && @allow_filters.any?{ |f| f[node] }
        runs = nil
      end
      runs
    end
  end
end
