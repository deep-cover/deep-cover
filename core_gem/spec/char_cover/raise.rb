### Basic kinds
    raise "hello" rescue nil
    raise TypeError rescue nil
    raise TypeError, "hello" rescue nil
    raise Errno::EEXIST, "hello" rescue nil

### from within an argument

    def foo(msg = nil, *)
      raise if msg == :raise
    end

    foo(foo, foo(:raise, foo(foo)), foo) rescue nil
#>  xxx-   -    -      -    -   --- xxx-
