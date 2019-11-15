### Positional arguments

    def foo(a, b = 42, c = 44); end; foo() rescue nil
#>         --- - - xx- - - xx-- ----    --
    def foo(a, b = 42, c = 44); end; foo(1)
#>         --- - -   - - -   -- ----    - -
    def foo(a, b = 42, c = 44); end; foo(1,2)
#>         --- - - xx- - -   -- ----    - - -
    def foo(a, b = 42, c = 44); end; foo(1,2,3)
#>         --- - - xx- - - xx-- ----    - - - -
    def foo(a, b = raise, c = 44); end; foo(1) rescue nil
#>         --- - -      - - - xx-- ----    - -

### Keyword arguments
    def foo(a: 42, b: 44, c: raise); end; foo(c: 1)
#>         ---   - --   - -- xxxxx-- ----    -    -
    def foo(a: 42, b: 44, c: raise); end; foo(c: 1, a: 2)
#>         --- xx- --   - -- xxxxx-- ----    -    -     -
    def foo(a: 42, b: 44, c: raise); end; foo(a: 1, b: 1) rescue nil
#>         --- xx- -- xx- --      -- ----    -    -     -
    def foo(a: 42, b: 44, c: raise); end; foo(c: 1, d: 666) rescue nil
#>         --- xx- -- xx- -- xxxxx-- ----    -    -       -

#### More than 32 (Ruby 2.3-2.5)
    # https://github.com/deep-cover/deep-cover/issues/47#issuecomment-477176061
    # We skip those default_argument trackers because it can mess things up, this way
    # 12 is still returned. Without the skip in node/arguments.rb, 0 would get returned!
    o = {}
    def o.foo(a0: 0, a1: 0, a2: 0, a3: 0, a4: 0, a5: 0, a6: 0, a7: 0, a8: 0, a9: 0,
#>           ---- x- --- x- --- x- --- x- --- x- --- x- --- x- --- x- --- x- --- x-
              b0: 0, b1: 0, b2: 0, b3: 0, b4: 0, b5: 0, b6: 0, b7: 0, b8: 0, b9: 0,
#>            --- x- --- x- --- x- --- x- --- x- --- x- --- x- --- x- --- x- --- x-
              c0: 0, c1: 0, c2: 0, c3: 0, c4: 0, c5: 0, c6: 0, c7: 0, c8: 0, c9: 0,
#>            --- x- --- x- --- x- --- x- --- x- --- x- --- x- --- x- --- x- --- x-
              d0: 0, d1: 0,
#>            --- x- --- x-
              x: 0
#>            -- x
             )
        x
    end
    assert o.foo(x: 12) == 12

#### More than 32 (Ruby 2.6+)
    # This was solved by Ruby: https://github.com/deep-cover/deep-cover/issues/47#issuecomment-477176061
    # So we should be handling it properly
    o = {}
    def o.foo(a0: 0, a1: 0, a2: 0, a3: 0, a4: 0, a5: 0, a6: 0, a7: 0, a8: 0, a9: 0,
        b0: 0, b1: 0, b2: 0, b3: 0, b4: 0, b5: 0, b6: 0, b7: 0, b8: 0, b9: 0,
        c0: 0, c1: 0, c2: 0, c3: 0, c4: 0, c5: 0, c6: 0, c7: 0, c8: 0, c9: 0,
        d0: 0, d1: 0,
        x: 0
#>      -- x
    )
        x
    end
    assert o.foo(x: 12) == 12



### Block arguments
    def foo(&block); end
#>         --------- ---
