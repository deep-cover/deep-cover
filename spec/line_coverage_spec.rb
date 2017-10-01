require "spec_helper"
require "tempfile"

RSpec::Matchers.define :not_be_higher_than_builtin_coverage do |fn, lines, lineno|
  match do
    Tempfile.open(["#{File.basename(fn)}_#{lineno}_", '.rb']) do |tmp|
      new_lines_added = lineno - 1
      tmp.write("\n" * new_lines_added + lines.join)
      tmp.close

      @builtin = DeepCover::Tools.builtin_coverage(tmp.path)[new_lines_added..-1]
      @our = DeepCover::Tools.our_coverage(tmp.path, not_higher_than_builtin: true)[new_lines_added..-1]
    end

    @our.zip(@builtin).all? do |us, ruby|
      ruby_exec = ruby && ruby > 0 || false
      us_exec = us && us > 0 || false

      # bad:
      # ruby_exec && !us_exec
      # !ruby_exec && us_exec
      bad = ruby_exec != us_exec

      good = us == ruby || ruby_exec && us_exec || ruby.nil? && us == 0

      binding.pry if good == bad # They should be equivalent... Otherwise there is mistake
      good
    end
  end
  failure_message do
    result = DeepCover::Tools.format(@builtin, @our, source: lines.join).join
    "Builtin & DeepCover's line coverage should match\n#{result}"
  end
end

RSpec.describe 'line coverage(not_higher_than_builtin: true)' do
  each_code_examples('./spec/branch_cover/*.rb') do |fn, lines, lineno|
    should not_be_higher_than_builtin_coverage(fn, lines, lineno)
  end
end
