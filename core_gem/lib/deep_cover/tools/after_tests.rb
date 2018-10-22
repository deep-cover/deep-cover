# frozen_string_literal: true

# This file is used by projects cloned with clone mode. As such, special care must be taken to
# be compatible with any projects.
# THERE MUST NOT BE ANY USE/REQUIRE OF DEPENDENCIES OF DeepCover HERE
# See deep-cover/core_gem/lib/deep_cover/setup/clone_mode_entry_template.rb for explanation of
# clone mode and of this top_level_module stuff.
top_level_module = Thread.current['_deep_cover_top_level_module'] || Object # rubocop:disable Lint/UselessAssignment

module top_level_module::DeepCover # rubocop:disable Naming/ClassAndModuleCamelCase
  module Tools
    module AfterTests
      extend self

      def after_tests
        use_at_exit = true
        if defined?(::Minitest)
          use_at_exit = false
          ::Minitest.after_run { yield }
        end
        if defined?(::Rspec)
          use_at_exit = false
          ::RSpec.configure do |config|
            config.after(:suite) { yield }
          end
        end
        if use_at_exit
          at_exit { yield }
        end
      end
    end
  end
end
