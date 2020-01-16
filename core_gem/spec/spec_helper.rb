# frozen_string_literal: true

if defined?($SPEC_HELPER_TRIED)
  puts "spec_helper.rb couldn't run properly and was executed again. Hopefully you got an exception from that."
  puts 'Exiting since you are already in trouble!'
  exit!(1)
end
$SPEC_HELPER_TRIED = true


require 'bundler/setup'
require 'pry'
require 'pathname'
require 'deep_cover'
require_relative 'specs_tools'
require_relative 'extensions'

# We wouldn't want some test passing / failing because of trackers from previous tests...
Dir[File.expand_path(__dir__ + '/../../**/*.dct')].each do |old_tracker_file|
  File.delete(old_tracker_file)
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.filter_run_excluding exclude: :JRuby if RUBY_PLATFORM == 'java'

  # Disable RSpec exposing methods globally on `Module` and `main`
  # config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end

# This option makes short-lived jruby processes run faster.
if RUBY_PLATFORM == 'java'
  JRUBY_DEV_OPTION = '--dev'
else
  JRUBY_DEV_OPTION = nil
end

def trivial_gem_coverage
  # We can only easily require this at most once, so we have to share...
  $trivial_gem_coverage ||= begin
    DeepCover.cover(paths: '.') { require_relative 'code_fixtures/trivial_gem/lib/trivial_gem' }
    require_relative 'code_fixtures/trivial_gem/lib/trivial_gem'
    # Kind of a pain to load the test properly, so cheat...
    TrivialGem.hello
    TrivialGem.branches(1)

    DeepCover.coverage
  end
end


if %w(true 1).include?(ENV['WITHOUT_PENDING'])
  # "Official" way of not showing pendings
  # https://github.com/rspec/rspec-core/issues/2377
  module FormatterOverrides
    def example_pending(_)
    end

    def dump_pending(_)
    end
  end

  RSpec::Core::Formatters::DocumentationFormatter.prepend FormatterOverrides
  RSpec::Core::Formatters::ProgressFormatter.prepend FormatterOverrides
end

CommandExecution = Struct.new(:stdout, :stderr, :exit_code)
def run_command(command, from_dir: nil)
  require 'open3'
  options = {}
  options[:chdir] = from_dir if from_dir

  if RUBY_PLATFORM == 'java'
    if command.is_a?(Array)
      command.shift if command[0] == 'ruby'
      command = %w(ruby --dev) + command
    else
      command = command[5..-1] if command.start_with?('ruby ')
      command = "ruby --dev #{command}"
    end
  end

  stdout, stderr, status = DeepCover::Tools.with_unbundled_env do
    Open3.capture3(*command, options)
  end
  CommandExecution.new(stdout.chomp, stderr.chomp, status.exitstatus)
end

RSpec::Matchers.define :have_expected_results do |stdout: nil, stderr: /^$/, exit_code: 0|
  match do |cmd_exec|
    raise 'Should receive the result of #run_command' unless cmd_exec.is_a?(CommandExecution)
    @cmd_exec = cmd_exec
    @expected_stdout = stdout
    @expected_stderr = stderr
    @expected_exit_code = exit_code

    # rubocop:disable Style/CaseEquality
    @stdout_ok = stdout.nil? || stdout === cmd_exec.stdout # Note: stdout is string or regex
    @stderr_ok = stderr.nil? || stderr === cmd_exec.stderr # Note: stderr is string or regex
    # rubocop:enable Style/CaseEquality
    @exit_code_ok = exit_code == cmd_exec.exit_code

    @stdout_ok && @stderr_ok && @exit_code_ok
  end

  failure_message do
    messages = []
    messages << "Bad exit_code: Expected exit_code: #{@expected_exit_code}\nReceived exit_code: #{@cmd_exec.exit_code}" unless @exit_code_ok
    messages << "Bad stdout: Expected stdout: #{@expected_stdout}\nReceived stdout: #{@cmd_exec.stdout}" unless @stdout_ok
    messages << "Bad stderr: Expected stderr: #{@expected_stderr}\nReceived stderr: #{@cmd_exec.stderr}" unless @stderr_ok

    messages << "exit_code was as expected: #{@cmd_exec.exit_code}" if @exit_code_ok
    messages << "Stdout was as expected: #{@cmd_exec.stdout}" if @stdout_ok
    messages << "Stderr was as expected: #{@cmd_exec.stderr}" if @stderr_ok

    messages.join("\n")
  end
end

RSpec::Matchers.define :run_successfully do
  match do |command|
    @matcher = have_expected_results(stdout: @expected_output)
    run_command(command, from_dir: @from_dir).should @matcher
    true
  end

  chain :and_output do |output|
    @expected_output = output
  end

  chain :from_dir do |dir|
    @from_dir = dir
  end

  failure_message do
    @matcher.failure_message
  end
end
