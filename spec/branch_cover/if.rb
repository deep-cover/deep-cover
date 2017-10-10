### One-liner
    42 if false
#>  xx
    42 if true
    42 unless false
    42 unless true
#>  xx

#### With raises
    (42 unless raise) rescue nil
#>   xx xxxxxx

    (42 if raise) rescue nil
#>   xx xx

    (raise if true) rescue nil

### Full form
    if false
      42
#>X
    end
#>  ---

    if true
      42
    end
#>  ---

    unless false
      42
    end
#>  ---

    unless true
      42
#>X
    end
#>  ---

#### With else

    if true || false
#>             xxxxx
      42
    else
#>X
      43
#>X
    end
#>  ---

    if false && true
#>              xxxx
      42
#>X
    else
      43
    end
#>  ---

#### With elsif
    if false
      :a
#>X
    elsif false
      :b
#>X
    elsif true
      :c
    elsif :whatever
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
#>  xxxxxxxxxxxxxxx
    else
#>X
    end) rescue nil
#>  ---x


   dummy_method(unless raise
#> xxxxxxxxxxxxxxxxxxx
   end)
#> ---x

#### With elsif
    if false
    elsif false
    elsif true
    elsif :whatever
#>X
    else
#>X
    end
#>  ---
### Ternary operator form
#### Simple
    x = false ? 1 : 2; assert(x == 2)
#>              x
    x = true ? 1 : 2; assert(x == 1)
#>               x x
