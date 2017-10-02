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

    # In ruby 2.0 and 2.1, using 2, 3 or 4 as lineno with RubyVM::InstructionSequence.compile
    # will cause the coverage result to be wrong.
    # 1: [1,2,nil,1]
    # 2: [nil,1,2,nil]
    # 3: [nil,nil,1,2]
    # 4: [nil,nil,nil,1]
    # 5: [nil,nil,nil,nil,1,2,nil,1]
    # Using 1 and 5 or more do not seem to show this issue.
    # The work around is to create the fake lines manually and always use the default lineno
    def self.compile(source, fn=nil, absolute_fn=nil, lineno=1)
      source = "\n" * (lineno - 1) + source
      RubyVM::InstructionSequence.compile(source, fn, absolute_fn)
    end
  end
end
