module AnotherComponentGem
  module Foo
    def hi
      Process.wait(fork { exec 'echo' } ) if Process.respond_to?(:fork)
      :there
    end
  end
end
