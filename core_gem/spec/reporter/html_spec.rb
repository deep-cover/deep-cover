# frozen_string_literal: true

require_relative '../spec_helper'

module DeepCover
  module Reporter
    RSpec.describe HTML do
      let(:coverage) { trivial_gem_coverage }

      describe HTML::Site do
        let(:site) { HTML::Site.new(coverage) }
        it 'renders the index' do
          html = site.render_index
          html.should include '"header":"Nodes"'
        end
        it 'renders the sources' do
          html = site.render_source('dummy_path', coverage.covered_codes.first)
          html.should include 'title="potentially_executable">8</span>'
        end
      end

      describe HTML::Index do
        let(:index) { HTML::Index.new(Reporter::Base.new(coverage.analysis)) }
        it {
          data = index.stats_to_data
          children = data.first.delete(:children)
          data.should ==
            [{text: 'lib',
              data: {node: {executed: 61, not_executed: 12, not_executable: 0, ignored: 0},
                     per_char: {executed: 262, not_executed: 22, not_executable: 304, ignored: 0},
                     branch: {executed: 1, not_executed: 7, not_executable: 0, ignored: 0},
                     node_percent: 83.56,
                     per_char_percent: 92.25,
                     branch_percent: 12.5,
                    },
              state: {opened: true},
              },
            ]
          children.size.should == 2
          children.first.should ==
            {text: '<a href="lib/trivial_gem.rb.html">trivial_gem.rb</a>',
             data: {node: {executed: 57, not_executed: 12, not_executable: 0, ignored: 0},
                    per_char: {executed: 231, not_executed: 22, not_executable: 293, ignored: 0},
                    branch: {executed: 1, not_executed: 7, not_executable: 0, ignored: 0},
                    node_percent: 82.61,
                    per_char_percent: 91.3,
                    branch_percent: 12.5,
                  },
            }
        }
      end
    end
  end
end
