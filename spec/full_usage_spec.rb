require "spec_helper"

RSpec::Matchers.define :run_successfully do
  match do |command|
    require 'open3'
    output, errors, status = Bundler.with_clean_env do
      Open3.capture3(*command)
    end
    @output = output.chomp
    @errors = errors.chomp
    @exit_code = status.exitstatus

    @ouput_ok = @expected_output.nil? || @expected_output == @output

    @exit_code == 0 && @ouput_ok && (@errors == '' || RUBY_PLATFORM == 'java')
  end

  chain :and_output do |output|
    @expected_output = output
  end

  failure_message do
    [
      ("expected output '#{@expected_output}', got '#{@output}'" unless @ouput_ok),
      ("expected exit code 0, got #{@exit_code}" if @exit_code != 0),
      ("expected no errors, got '#{@errors}'" unless @errors.empty?),
    ].compact.join(' and ')
  end
end

RSpec.describe 'DeepCover usage' do
  it { %w(ruby spec/full_usage/simple/simple.rb).should run_successfully.and_output('Done') }

  it do
    %w(ruby spec/full_usage/with_configure/test.rb).should run_successfully.and_output('[1, 0, 2, 0, nil, 2, nil, nil]')
  end

  it 'Can still require gems when there is no bundler' do
    "gem install --local spec/cli_fixtures/trivial_gem/pkg/trivial_gem-0.1.0.gem".should run_successfully
    %(ruby -e 'require "./lib/deep_cover"; DeepCover.start; require "trivial_gem"').should run_successfully
  end

end
