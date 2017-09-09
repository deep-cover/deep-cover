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

### Empty branches
#### Raises
    begin
      dummy_method(if raise
#>    xxxxxxxxxxxxx--
     else
#>   ----
     end)
#>   ---x
   rescue
   end

   begin
     dummy_method(unless raise
#>   xxxxxxxxxxxxx------
     end)
#>   ---x
    rescue
    end

#### With elsif
    if false
    elsif false
    elsif true
    elsif :whatever
#>  ----- xxxxxxxxx
    else
#>  ----
    end
