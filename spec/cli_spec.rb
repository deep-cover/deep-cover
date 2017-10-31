require "spec_helper"

module DeepCover
  RSpec.describe 'CLI' do
    describe 'deep-cover' do
      it 'can cover a simple gem' do
        out = `exe/deep-cover spec/cli_fixtures/trivial_gem -o=false --no-bundle`
        out.should =~ Regexp.new(%w[trivial_gem.rb 83.33 100 50].join('[ |]*'))
        out.should include '2 examples, 0 failures'
      end

      it 'can cover a single component gem like activesupport' do
        out = `exe/deep-cover spec/cli_fixtures/rails_like_gem/component_gem -o=false --no-bundle`
        out.should =~ Regexp.new(%w[component_gem.rb 80 100 50].join('[ |]*'))
        out.should include '1 example, 0 failures'
        out.should_not include 'another_component'
      end
    end
  end
end
