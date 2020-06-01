# frozen_string_literal: true

module DeepCover
  class CLI
    desc "run-expression [OPTIONS] ['ruby code']", 'Show coverage results for the given ruby expression (or STDIN)'
    option '--profile', desc: 'use profiler', type: :boolean if RUBY_PLATFORM != 'java'
    option '--debug', aliases: '-d', desc: 'opens an interactive console for debugging', type: :boolean
    def run_expression(expression = nil)
      require_relative '../../expression_debugger'
      expression ||= STDIN.read.tap { STDIN.reopen('/dev/tty') }
      ExpressionDebugger.new(expression, **options.transform_keys(&:to_sym)).show
    end
  end
end
