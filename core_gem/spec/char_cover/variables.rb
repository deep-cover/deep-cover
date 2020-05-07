### Local variables
    foo = 1
    dummy_method foo

#### Raise
    (bar = raise) rescue nil
#>  -xxx x      -

    dummy_method raise, bar rescue nil
#>  xxxxxxxxxxxx      - xxx


### Instance variables
    @foo = 1
    dummy_method @foo

#### Raise
    (@bar = raise) rescue nil
#>  -xxxx x      -

    dummy_method raise, @bar rescue nil
#>  xxxxxxxxxxxx      - xxxx


### Class
    class SomeClass
      @@foo = 1
      dummy_method @@foo
    end

#### Raise
    class SomeClass
      @@bar = nil
      (@@bar = raise) rescue nil
#>    -xxxxx x      -

      dummy_method raise, @@bar rescue nil
#>    xxxxxxxxxxxx      - xxxxx
    end


### Global
    $_some_nowhere_global = 1
    dummy_method $_some_nowhere_global

#### Raise
    ($_some_nowhere_global = raise) rescue nil
#>  -xxxxxxxxxxxxxxxxxxxxx x      -

    dummy_method raise, $_some_nowhere_global rescue nil
#>  xxxxxxxxxxxx      - xxxxxxxxxxxxxxxxxxxxx
