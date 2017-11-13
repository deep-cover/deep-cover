# frozen_string_literal: true

module DeepCover
  module Analyser::OptionallyCovered
    def optionally_covered
      @optionally_covered ||= Analyser
                              .constants.map { |c| Analyser.const_get(c) }
                              .select { |klass| klass < Analyser }
                              .flat_map do |klass|
                                klass.instance_methods(false).map do |method|
                                  method =~ /^is_(.*)\?$/
                                  Regexp.last_match(1)
                                end
                              end
                              .compact
                              .map(&:to_sym)
    end
  end
end
