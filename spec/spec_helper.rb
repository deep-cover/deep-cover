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

def trivial_gem_coverage
  # We can only easily require this at most once, so we have to share...
  $trivial_gem_coverage ||= begin
    DeepCover.cover(paths: 'spec') { require_relative 'cli_fixtures/trivial_gem/lib/trivial_gem' }
    require_relative 'cli_fixtures/trivial_gem/lib/trivial_gem'
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

RSpec::Matchers.define :run_successfully do
  match do |command|
    require 'open3'
    options = {}
    options[:chdir] = @from_dir if @from_dir

    output, errors, status = Bundler.with_clean_env do
      Open3.capture3(*command, options)
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

  chain :from_dir do |dir|
    @from_dir = dir
  end

  failure_message do
    [
      ("expected output '#{@expected_output}', got '#{@output}'" unless @ouput_ok),
      ("expected exit code 0, got #{@exit_code}" if @exit_code != 0),
      ("expected no errors, got '#{@errors}'" unless @errors.empty?),
    ].compact.join(' and ')
  end
end
