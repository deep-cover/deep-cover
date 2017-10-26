module DeepCover
  module Tools::ExecuteSample
    # Returns true if the code would have continued, false if the rescue was triggered.
    def execute_sample(to_execute)
      # Disable some annoying warning by ruby. We are testing edge cases, so warnings are to be expected.
      begin
        Tools.silence_warnings do
          if to_execute.is_a?(CoveredCode)
            to_execute.execute_code
          else
            to_execute.call
          end
        end
        true
      rescue RuntimeError => e
         # In our samples, a simple `raise` doesn't need to be rescued
         # Other exceptions are not rescued
        raise unless e.message.empty?
        false
      end
    end
  end
end
