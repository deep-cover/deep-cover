# frozen_string_literal: true

module DeepCover
  module Tools
    module AfterTests
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
