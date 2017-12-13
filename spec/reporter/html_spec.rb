# frozen_string_literal: true

require 'spec_helper'

module DeepCover
  module Reporter
    RSpec.describe HTML do
      let(:coverage) { trivial_gem_coverage }

      describe HTML::Site do
        let(:site) { HTML::Site.new(coverage.covered_codes) }
        it 'renders the index' do
          html = site.render_index
          html.should include '"header":"Nodes"'
        end
        it 'renders the sources' do
          html = site.render_source(coverage.covered_codes.first)
          html.should include 'title="potentially_executable">8</span>'
        end
      end

      describe HTML::Index do
        let(:index) { HTML::Index.new(coverage.analysis, {}) }
        it {
          data = index.stats_to_data
          children = data.first.delete(:children)
          data.should ==
            [{text: 'cli_fixtures/trivial_gem/lib',
              data: {node: {executed: 60, not_executed: 13, not_executable: 0, ignored: 0},
                     per_char: {executed: 262, not_executed: 22, not_executable: 304, ignored: 0},
                     branch: {executed: 1, not_executed: 7, not_executable: 0, ignored: 0},
                     node_percent: 82.19,
                     per_char_percent: 92.25,
                     branch_percent: 12.5,
                    },
              state: {opened: true},
              },
            ]
          children.size.should == 2
          children.first.should ==
            {text: '<a href="cli_fixtures/trivial_gem/lib/trivial_gem.rb.html">trivial_gem.rb</a>',
             data: {node: {executed: 56, not_executed: 13, not_executable: 0, ignored: 0},
                    per_char: {executed: 231, not_executed: 22, not_executable: 293, ignored: 0},
                    branch: {executed: 1, not_executed: 7, not_executable: 0, ignored: 0},
                    node_percent: 81.16,
                    per_char_percent: 91.3,
                    branch_percent: 12.5,
                  },
            }
        }
      end

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
