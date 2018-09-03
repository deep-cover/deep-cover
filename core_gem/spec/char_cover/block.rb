### Block never yielded to

    0.times do |i|
      42
#>X
    end.
#>  ---
      to_s

### Block never completed to

    def with_block_returning
      42.times do |i|
        return i if i > 20
      end.to_s
#>    ---xxxxx
    end
    with_block_returning
    assert_counts(DeepCover::Node::Block, flow_entry: 1, flow_completion: 0, execution: 1)

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
    dummy_method([]).unshift 42.to_s, 43 do ; end
    Kernel.puts(1, raise, 2) do ; 42; end
#>        xxxxx- -      - x- -- - xx- ---

### With safe navigation [#11] (Ruby 2.3+)

    nil&.each{}.to_s
#>       xxxx--
    [42]&.each{|*|}.to_s # missed_empty_branch
#>            -----
