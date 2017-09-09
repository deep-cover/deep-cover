### One-liner
    42 if false
#>  xx
    42 if true
    42 unless false
    42 unless true
#>  xx

#### With raises
    begin
      42 unless raise
#>    xx
    rescue
    end

    begin
      42 if raise
#>    xx
    rescue
    end

    begin
      raise if true
    rescue
    end

### Full form
    if false
      42
#>X
    end

    if true
      42
    end

    unless false
      42
    end

    unless true
      42
#>X
    end

#### With else

    if true || false
#>             xxxxx
      42
    else
      43
#>X
    end

    if false && true
#>              xxxx
      42
#>X
    else
      43
    end

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


#### With raises
    begin
      dummy_method(if raise
#>    xxxxxxxxxxxx
        42
#>      xx
      end)
    rescue
    end
