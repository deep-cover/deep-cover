### from within an argument

    def foo(msg = nil, *)
      raise if msg == :raise
    end

    foo(foo, foo(:raise, foo(foo)), foo) rescue nil
#>  xxx                             xxx
