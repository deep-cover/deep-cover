### Block yielded to

    0.times do |i|
      42
#>X
    end.
#>  ---
      to_s

### Method raises

    begin
      0.foo do |i|
#>          -- ---
        42
#>X
      end.
#>    ---x
        to_s
#>X
    rescue
    end

### Block yielded

    1.times do |i|
#>          -- ---
      42
    end.
#>  ---
      to_s

### Block yielded to and raises

    1.times do |i|
#>          -- ---
      raise
      42
#>X
    end.
#>  ---x
      to_s
#>X

### Empty Block
  1.times{}
