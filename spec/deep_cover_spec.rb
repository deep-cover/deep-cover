require "spec_helper"

RSpec.describe DeepCover do
  describe "cover" do
    it "temporarily overrides `require`, `require_relative` and `autoload`" do
      methods = %i[require require_relative]
      methods << :autoload unless RUBY_PLATFORM == 'java'
      2.times do
        sources = nil
        DeepCover.cover do
          sources = methods.map{|m| method(m).source_location }
        end
        sources.compact.size.should == methods.size
        methods.map{|m| method(m).source_location }.compact.size.should == 0
      end
    end

    it "doesn't choke on libs with encoding snafus" do
      DeepCover.cover do
        expect {
          require('rexml/source').should == true
        }.to output(/Can't cover .*rexml\/source.rb because of incompatible encoding/).to_stderr
      end
      REXML::SourceFactory.should be_instance_of(Class)
    end
  end

end
