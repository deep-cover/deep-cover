require "bundler/setup"
require 'pry'
require "deep_cover"
require_relative "tools"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

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

  RSpec::Core::Formatters::DocumentationFormatter.send(:prepend, FormatterOverrides)
  RSpec::Core::Formatters::ProgressFormatter.send(:prepend, FormatterOverrides)
end
