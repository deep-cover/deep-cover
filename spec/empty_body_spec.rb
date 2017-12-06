# frozen_string_literal: true

require 'spec_helper'

module DeepCover
  describe Node::EmptyBody do
    def expect_empty_node_position(test)
      code = test.sub(/<(\d)>/, '')
      nb = Integer(Regexp.last_match[1])
      ["\n", ';'].each do |delimiter|
        node = yield(Node[code.tr('|', delimiter)], nb)
        node.should be_instance_of Node::EmptyBody
        e = node.expression
        result = code.dup
        result[e.begin_pos...e.end_pos] = "<#{nb}>"
        result.should == test
      end
    end

    it 'has the right positions for all branches' do
      branches = <<-RUBY
        if     :foo|<0>end
        unless :foo|<1>end
        if     :foo|<0>else|end
        if     :foo|else|<1>end
        unless :foo|else|<0>end
        case|when :foo|<0>end
        case|when :foo then<0>|end
        case|when :foo|<0>else|end
        case|when :foo|else|<1>end
        case|when :foo|when :bar|<1>else|end
      RUBY
      branches.lines.each do |test|
        expect_empty_node_position(test) { |node, nb| node.branches[nb] }
      end
    end

    it 'has the right positions for all defs' do
      defs = <<-RUBY
        def eb|<2>end
        def eb(arg)|<2>end
        def self.eb|<3>end
        def self.eb(arg)|<3>end
      RUBY
      defs.lines.each do |test|
        expect_empty_node_position(test) { |node, nb| node[nb] }
      end
    end

    it 'has the right positions for rescue' do
      [
        :rescue,  'begin|<0>rescue|end',
        :resbody, 'begin|rescue|<2>end',
        :resbody, 'begin|rescue Exception|<2>end',
        :resbody, 'begin|rescue Exception=>e|<2>end',
        :ensure, 'begin|rescue|ensure|<1>end',
      ].each_slice(2) do |lookup, test|
        expect_empty_node_position(test) { |node, nb| node[lookup][nb] }
      end
    end
  end
end
