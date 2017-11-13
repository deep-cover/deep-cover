# frozen_string_literal: true

module DeepCover
  module Tools::SilenceWarnings
    # copied from: activesupport/lib/active_support/core_ext/kernel/reporting.rb
    def silence_warnings
      with_warnings(nil) { yield }
    end

    def with_warnings(flag)
      old_verbose, $VERBOSE = $VERBOSE, flag
      yield
    ensure
      $VERBOSE = old_verbose
    end
  end
end
