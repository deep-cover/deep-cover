if $SPEC_HELPER_TRIED
  puts "spec_helper.rb couldn't run properly and was executed again. Hopefully you got an exception from that."
  puts "Exiting since you are already in trouble!"
  exit!(1)
end
$SPEC_HELPER_TRIED = true


require "bundler/setup"
require 'pry'
$LOAD_PATH.unshift('../covered_deep_cover') if ENV["CC"]
require "deep_cover"
require_relative "specs_tools"
require_relative "extensions"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.filter_run_excluding exclude: :JRuby if RUBY_PLATFORM == 'java'

  # Disable RSpec exposing methods globally on `Module` and `main`
  # config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end

if %w(true 1).include?(ENV["WITHOUT_PENDING"])
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
