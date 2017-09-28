require "spec_helper"


RSpec.describe DeepCover do
  it "Can create a CoveredCode with empty source" do
    expect { DeepCover::CoveredCode.new(source: '') }.not_to raise_error
  end
end
