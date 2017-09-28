require "spec_helper"
require "tempfile"

RSpec::Matchers.define :match_builtin_coverage do |fn, lines, lineno|
  match do
    Tempfile.open(["#{File.basename(fn)}_#{lineno}_", '.rb']) do |tmp|
      new_lines_added = lineno - 1
      tmp.write("\n" * new_lines_added + lines.join)
      tmp.close

      @builtin = DeepCover::Tools.builtin_coverage(tmp.path)[new_lines_added..-1]
      @our = DeepCover::Tools.our_coverage(tmp.path)[new_lines_added..-1]
    end

    @our.zip(@builtin).all? do |us, ruby|
      # accept us > ruby > 0; can happen for example with `def foo(arg = this_can_run_many_times)`
      cmp = us <=> ruby
      cmp && (cmp == 0 || (cmp > 0 && ruby > 0)) # either equal, or us > ruby > 1
    end
  end
  failure_message do
    result = DeepCover::Tools.format(@builtin, @our, source: lines.join).join
    "Builtin & DeepCover's line coverage should match\n#{result}"
  end
end

RSpec.describe 'line coverage' do
  each_code_examples('./spec/branch_cover/*.rb') do |fn, lines, lineno|
    should match_builtin_coverage(fn, lines, lineno)
  end
end
