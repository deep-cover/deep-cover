# frozen_string_literal: true

require_relative '../spec_helper'

module DeepCover
  module Reporter
    RSpec.describe Text do
      let(:coverage) { trivial_gem_coverage }
      let(:fixtures) { Pathname("#{__dir__}/fixtures") }
      let(:options) { {} }
      let(:text) { Text.new(coverage, **options) }
      let(:subject) { text.report }
      describe 'with no ignored' do
        it { should == fixtures.join('text_report_no_ignored.txt').read.chomp }
      end
      describe 'with ignored' do
        let(:options) { {ignore_uncovered: %i[raise default_argument]} }
        it { should == fixtures.join('text_report_with_ignored.txt').read.chomp }
      end
    end
  end
end
