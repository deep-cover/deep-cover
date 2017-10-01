module DeepCover
  module Misc
    def self.require_relative_dir(dir_name)
      dir = File.dirname(caller.first.partition(/\.rb:\d/).first)
      Dir["#{dir}/#{dir_name}/*.rb"].sort.each do |file|
        require file
      end
    end

    # Call with nil to remove $VERBOSE while in the block
    # copied from: https://apidock.com/rails/v4.2.7/Kernel/with_warnings
    def self.with_warnings(flag)
      old_verbose, $VERBOSE = $VERBOSE, flag
      yield
    ensure
      $VERBOSE = old_verbose
    end
  end
end
