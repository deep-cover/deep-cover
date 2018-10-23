# frozen_string_literal: true

module DeepCover
  class CLI
    desc 'run-expression [OPTIONS] expression_to_debug', 'Show coverage results for the given expression'
    option '--profile', desc: 'use profiler', type: :boolean if RUBY_PLATFORM != 'java'
    option '--debug', aliases: '-d', desc: 'opens an interactive console for debugging', type: :boolean
    def run_expression(expression)
      require_relative '../expression_debugger'
      ExpressionDebugger.new(expression, **options.transform_keys(&:to_sym)).show
    end
  end
end
