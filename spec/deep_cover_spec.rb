require "spec_helper"

RSpec::Matchers.define :match_coverage do
  match do |fn|
    @our = DeepCover::Tools.our_coverage(fn)
    @builtin = DeepCover::Tools.builtin_coverage(fn)
    @our.zip(@builtin).all? do |us, ruby|
      # accept us > ruby > 0; can happen for example with `def foo(arg = this_can_run_many_times)`
      cmp = us <=> ruby
      cmp && (cmp == 0 || (cmp > 0 && ruby > 0)) # either equal, or us > ruby > 1
    end
  end
  failure_message do |fn|
    DeepCover::Tools.format(@builtin, @our, filename: fn).join
  end
end

RSpec.describe DeepCover do
  Dir.glob('./spec/samples/*.rb').each do |fn|
    it "returns the same coverage for '#{File.basename(fn, '.rb')}' as the builtin one" do
      File.absolute_path(fn).should match_coverage
    end
  end

  it "Can create a CoveredCode with empty source" do
    expect { DeepCover::CoveredCode.new(source: '') }.not_to raise_error
  end
end
