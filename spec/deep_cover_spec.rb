require "spec_helper"

RSpec.describe DeepCover do
  it "Can create a CoveredCode with empty source" do
    expect { DeepCover::CoveredCode.new(source: '') }.not_to raise_error
  end

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
  end

end
