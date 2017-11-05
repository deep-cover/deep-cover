### Block never yielded to

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
#### with no arguments
    1.times{}

#### with arguments [#6]
    lambda { |*_| }

#### Failures in devise [#6]
    dummy_method 42.to_s, *nil do ; end
    Kernel.puts(1, raise, 2) do ; 42; end
#>        xxxxx- -      - x- -- - xx- ---

### With safe navigation [#11] (Ruby 2.3+)

    nil&.each{}.to_s
#>       xxxx--
    [42]&.each{|*|}.to_s
#>            -----
