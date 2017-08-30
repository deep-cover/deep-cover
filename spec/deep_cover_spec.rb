require "spec_helper"

RSpec::Matchers.define :match_coverage do
  match do |fn|
    @our = our_coverage(fn)
    @builtin = builtin_coverage(fn)
    @our == @builtin
  end
  failure_message_for_should do |fn|
    format(fn, @builtin, @our).join
  end
end

RSpec.describe DeepCover do
  Dir.glob('./spec/samples/*.rb').each do |fn|
    it "returns the same coverage for '#{File.basename(fn)}' as the builtin one" do
      fn.should match_coverage
    end
  end
end
