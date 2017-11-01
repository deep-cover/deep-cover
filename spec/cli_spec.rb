require "spec_helper"

module DeepCover
  RSpec.describe 'CLI' do
    describe 'The output of deep-cover' do
      let(:command) { "exe/deep-cover spec/cli_fixtures/#{path} -o=false --no-bundle"}
      let(:output) { Bundler.with_clean_env{ `#{command}` } }
      subject { output }
      describe 'for a simple gem' do
        let(:path) { 'trivial_gem' }
        it do
          should =~ Regexp.new(%w[trivial_gem.rb 83.33 100 50].join('[ |]*'))
          should include '2 examples, 0 failures'
        end
      end

      describe 'for a single component gem like activesupport' do
        let(:path) { 'rails_like_gem/component_gem' }
        it do
          should =~ Regexp.new(%w[component_gem.rb 80 100 50].join('[ |]*'))
          should include '1 example, 0 failures'
          should_not include 'another_component'
        end
      end

      describe 'for a multiple component gem like rails' do
        let(:path) { 'rails_like_gem' }
        it do
          should =~ Regexp.new(%w[component_gem.rb 80 100 50].join('[ |]*'))
          should =~ Regexp.new(%w[foo.rb 100 100 100].join('[ |]*'))
          should include '1 example, 0 failures'
          should include 'another_component'
          should include '2 examples, 1 failure'
        end
      end
    end
  end
end
