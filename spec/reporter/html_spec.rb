# frozen_string_literal: true

require 'spec_helper'
require 'deep_cover/reporter/html'

module DeepCover
  module Reporter
    RSpec.describe HTML do
      describe HTML::Tree do
        include HTML::Tree
        it { path_to_partial_paths('a/b/c').should == %w[a b c] }
        it { list_to_twig(%i[a b c]).should == {a: {b: {c: {}}}} }
        it {
          deep_merge([{a: {b: {c: {}}}},
                      {a: {b: {d: {}}}},
                     ]).should ==
            {a: {b: {c: {}, d: {}}}}
        }
        it {
          simplify(a: {b: {c: {}, d: {}}}).should ==
            {'a/b' => {c: {}, d: {}}}
        }

        let(:paths) { %w[abcd xyz abcef abceg abch].map { |s| s.split('').join('/') } }
        it {
          paths_to_tree(paths).should == {
                                           'a/b/c' => {'d' => {}, 'e' => {'f' => {}, 'g' => {}}, 'h' => {}},
                                           'x/y/z' => {},
                                         }
        }
      end
    end
  end
end
