# frozen_string_literal: true

require_relative '../spec_helper'

module DeepCover
  class IgnoreNodes
    include RSpec::Matchers

    def initialize(*nodes, of:)
      @nodes = nodes.map(&:to_s)
      @source = of
    end

    def description
      "ignore the nodes #{@nodes}"
    end

    def matches?(option)
      node = Node[@source]
      with = Analyser::Node.new(node, ignore_uncovered: option)
      without = Analyser::Node.new(node)
      @matchers = [*results(without), *results(with)].map { |a| match_array(a) }
      expected = [@nodes, [], [], @nodes]
      if option == nil
        @matchers.shift(2)
        expected.shift(2)
      end
      @err = @matchers.zip(expected).map do |m, values|
        m.failure_message unless m.matches?(values)
      end.compact
      @err.empty?
    end

    # returns not_covered, ignored
    def results(analyser)
      r = analyser.results
      [0, nil].map do |val|
        r.select { |node, runs| runs == val }
         .keys
         .map(&:source)
      end
    end

    def failure_message
      @err.join(' and ')
    end
  end

  RSpec.describe Analyser::Node do
    def ignore_nodes(*nodes, of:)
      IgnoreNodes.new(*nodes, of: of)
    end

    describe :ignore_uncovered do
      it { :default_argument.should ignore_nodes(1, [], of: <<-RUBY) }
          def foo(foo = 1, bar = [], baz = 4)
            :ok
          end
          foo(:a, :b)
      RUBY

      it { :raise.should ignore_nodes("raise 'oops'", "'oops'", of: <<-RUBY) }
          raise 'oops' if 1 + 1 == 3
      RUBY

      it { :trivial_if.should ignore_nodes(42, 'foo(42)', of: <<-RUBY) }
          foo(42) if false
      RUBY

      it { :warn.should ignore_nodes("warn 'yo'", "'yo'", of: <<-RUBY) }
          warn 'yo' if 1 + 1 == 3
      RUBY

      it { nil.should ignore_nodes(42, 'foo(42)', of: <<-RUBY) }
          if false
            foo(42) # nocov
          end
      RUBY

      DeepCover.config.ignore_uncovered :test_custom_filter do
        type == :int
      end

      it { :test_custom_filter.should ignore_nodes('42', of: <<-RUBY) }
          42 if false
      RUBY
    end
  end
end
