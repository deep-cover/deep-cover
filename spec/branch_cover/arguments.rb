### Positional arguments

    def foo(a, b = 42, c = 44); end; foo() rescue nil
#>      -----  - - xx  - - xx
    def foo(a, b = 42, c = 44); end; foo(1)
#>      -----  - -     - -
    def foo(a, b = 42, c = 44); end; foo(1,2)
#>      -----  - - xx  - -
    def foo(a, b = 42, c = 44); end; foo(1,2,3)
#>      -----  - - xx  - - xx
    def foo(a, b = raise, c = 44); end; foo(1) rescue nil
#>      -----  - -        - - xx

### Keyword arguments
    def foo(a: 42, b: 44, c: raise); end; foo(c: 1)
#>      ------     --     -- xxxxx
    def foo(a: 42, b: 44, c: raise); end; foo(c: 1, a: 2)
#>      ------ xx  --     -- xxxxx
    def foo(a: 42, b: 44, c: raise); end; foo(a: 1, b: 1) rescue nil
#>      ------ xx  -- xx  --
    def foo(a: 42, b: 44, c: raise); end; foo(c: 1, d: 666) rescue nil
#>      ------ xx  -- xx  -- xxxxx

### Block arguments
    def foo(&block); end
#>      ----------
