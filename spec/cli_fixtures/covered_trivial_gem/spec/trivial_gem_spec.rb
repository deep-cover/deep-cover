require "spec_helper"

RSpec.describe CoveredTrivialGem do
  it "has a version number" do
    expect(CoveredTrivialGem::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(CoveredTrivialGem.hello).to eq(:world)
  end

  it "runs a bunch of branches" do
    expect(CoveredTrivialGem.branches(1)).to eq(1)
  end
end
