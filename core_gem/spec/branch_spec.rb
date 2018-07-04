# frozen_string_literal: true

require_relative 'spec_helper'

module DeepCover
  # rubocop:disable Layout/IndentHash
  # rubocop:disable Performance/RedundantMerge
  RSpec.describe Node::Branch do
    describe :branches_summary do
      tests = {
        'if :foo then :bar else :baz end' => {
          0 => 'truthy branch',
          1 => 'falsy branch',
          [0, 1] => 'truthy branch and falsy branch',
        },
        ':bar if :foo' => {
          0 => 'truthy branch',
          1 => 'implicit falsy branch',
        },
        ':bar unless :foo' => {
          0 => 'implicit truthy branch',
          1 => 'falsy branch',
        },
        ':foo ? :bar : :baz' => {
          0 => 'truthy branch',
          1 => 'falsy branch',
        },
        ':foo || :bar' => {
          0 => 'right-hand side',
          1 => 'truthy shortcut',
        },
        ':foo && :bar' => {
          0 => 'right-hand side',
          [0, 1] => 'right-hand side and falsy shortcut',
        },
        'case :foo when :bar then :baz;when :qux then :xyz;else;42;end' => {
          0 => '1 when clause',
          [0, 1] => '2 when clauses',
          [0, 1, 2] => '2 when clauses and else',
          2 => 'else',
        },
      }
      tests.merge!('nil&.foo' => {
          0 => 'nil shortcut',
          1 => 'safe send',
          [0, 1] => 'nil shortcut and safe send',
        }) if RUBY_VERSION >= '2.3'
      tests.each do |code, answers|
        answers.each do |which, expected|
          it do
            branch = Node[code][Node::Branch]
            branch.branches_summary(branch.branches.values_at(*which)).should == expected
          end
        end
      end
    end
  end
  # rubocop:enable Layout/IndentHash
  # rubocop:enable Performance/RedundantMerge
end
