### Return
#### no arg
    def foo
      1
      return
      2
#>X
    end; foo

#### multiple args
    def foo
      1
      return 2, 3
      4
#>X
    end; foo

#### within block
    def foo
      1.times { return 2 }
      3
#>X
    end; foo

#### out of scope
    def foo(&block)
      block
    end
    def bar
      foo { return 42 }
    end
    bar.call.to_s rescue nil
#>          xxxxx

#### with raising argument
    def foo
      return raise
#>    xxxxxx
    end; foo

### defined?
    foo if defined? IsNotDefinedAnywhere
#>  xxx             --------------------
