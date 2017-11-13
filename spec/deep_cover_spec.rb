# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeepCover do
  describe 'cover' do
    it 'temporarily overrides `require`, `require_relative` and `autoload`' do
      methods = %i[require require_relative]
      methods << :autoload unless RUBY_PLATFORM == 'java'
      2.times do
        sources = nil
        DeepCover.cover do
          sources = methods.map { |m| method(m).source_location }
        end
        sources.compact.size.should == methods.size
        methods.map { |m| method(m).source_location }.compact.size.should == 0
      end
    end

    it "doesn't choke on libs with encoding snafus" do
      begin
        prev = DeepCover.config.paths
        DeepCover.config.paths '/'
        DeepCover.cover do
          expect do
            require('rexml/source').should == true
          end.to output(%r[Can't cover .*rexml/source.rb because of incompatible encoding]).to_stderr
        end
      ensure
        DeepCover.config.paths prev
      end
      REXML::SourceFactory.should be_instance_of(Class)
    end
  end
end
