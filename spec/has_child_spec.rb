require "spec_helper"

module DeepCover
  class Parent
    attr_reader :children
    include HasChild
    # Make all private methods public for testing purposes
    class << self
      public *HasChild::ClassMethods.private_instance_methods(false)
    end
  end

  class ParentNoRest < Parent
    has_child foo: String
    has_child bar: Integer
  end

  class ParentWithRest < Parent
    has_child foo: String
    has_child bar: Integer, rest: true
    has_child baz: Float
    has_child qux: Hash
  end

  RSpec.describe HasChild do
    describe "constants" do
      it "CHILDREN is set" do
        ParentNoRest::CHILDREN.should eql(foo: 0, bar: 1)
        ParentWithRest::CHILDREN.should eql(foo: 0, bar: 1..-3, baz: -2, qux: -1)
      end

      it "children's are set" do
        ParentNoRest::BAR.should eql 1
        ParentWithRest::BAR.should eql 1..-3
      end
    end

    describe :expected_types do
      it "works" do
        ParentNoRest.expected_types([]).should eql [String, Integer]
        ParentWithRest.expected_types([]).should eql [String, Float, Hash]
        ParentWithRest.expected_types(Array.new(5)).should eql [String, Integer, Integer, Float, Hash]
      end
    end

    describe :check_children_types do
      it "works" do
        ParentNoRest.check_children_types(['x', 1]).should eql []
        ParentNoRest.check_children_types([1, 'x']).should eql [[1, String], ['x', Integer]]
        ParentWithRest.check_children_types(['x', 1, 2, 3, 4, 4.5, 'h']).should eql [['h', Hash]]
      end
    end

    describe :node_matches_type? do
      it "works" do
        Parent.node_matches_type?(5, Integer).should eql true
        Parent.node_matches_type?(5, [Integer, nil]).should eql true
        Parent.node_matches_type?(nil, [Integer, nil]).should eql true
        Parent.node_matches_type?('5', [Integer, nil]).should eql false
        Parent.node_matches_type?('5', :any).should eql true
      end
    end

    describe :node_matches_type? do
      it "works" do
        ParentWithRest.child_index_to_name(0, 5).should eql :foo
        ParentWithRest.child_index_to_name(1, 5).should eql :bar
        ParentWithRest.child_index_to_name(2, 5).should eql :bar
        ParentWithRest.child_index_to_name(3, 5).should eql :baz
        ParentWithRest.child_index_to_name(4, 5).should eql :qux
        ParentWithRest.child_index_to_name(1, 3).should eql :baz
        expect(->{ ParentNoRest.child_index_to_name(3, 4)}).to raise_error(IndexError)
      end
    end


  end
end
