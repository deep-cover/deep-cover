### One-liner
    a = 42 if falsx; assert a == nil
#>  x x xx         -
    b = 42 if trux; assert b == 42
    c = 42 unless falsx; assert c == 42
    d = 42 unless trux; assert d == nil
#>  x x xx            -

#### With raises
    (42 unless raise) rescue nil
#>  -xx xxxxxx      -

    (42 if raise) rescue nil
#>  -xx xx      -

    (raise if trux) rescue nil

### Full form
    if falsx
      42
#>X
    end
#>  ---

    if trux
      42
    end
#>  ---

    unless falsx
      42
    end
#>  ---

    unless trux
      42
#>X
    end
#>  ---

#### With else

    if trux
      42
    else
#>X
      43
#>X
    end
#>  ---

    if falsx
      42
#>X
    else
      43
    end
#>  ---

    unless falsx
      42
    else
#>X
      43
#>X
    end
#>  ---

    unless trux
      42
#>X
    else
      43
    end
#>  ---

#### With elsif
    if falsx
      :a
#>X
    elsif falsx
      :b
#>X
    elsif trux
      :c
    elsif falsx
#>X
      :d
#>X
    else
#>X
    end
#>  ---

### Empty branches
#### Raises
    dummy_method(if raise
#>  xxxxxxxxxxxx-xx
    else
#>X
    end) rescue nil
#>  ----


    dummy_method(unless raise
#>  xxxxxxxxxxxx-xxxxxx
    end)
#>  ----

#### With elsif
    if falsx
    elsif falsx
    elsif trux
    elsif falsx
#>X
    else
#>X
    end
#>  ---
### Ternary operator form
#### Simple
    x = falsx ? 1 : 2; assert(x == 2)
#>              x    -       -      -
    x = trux ? 1 : 2; assert(x == 1)
#>               x x-       -      -
