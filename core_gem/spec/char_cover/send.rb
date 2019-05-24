### With parenthesis
    [].push(1, 2, 3)

#### Nested
    [].push(1, [].push(2), 3)

### Without outer parenthesis
    [].push 1, [].push(2), 3

### [] and .[]
    foo = []
    foo[1]
    foo.[](3)
    foo.[] 3

### []= and .[]=
    foo = []
    foo[1] = 2
#>
    foo.[]=(3, 4)
    foo.[]= 3, 4
#>           -

#### with raise
    foo = []
    foo[raise] rescue nil
#>     x     x
    foo[raise] = 2
#>     x     xxxxx

### .()
    a = proc {|o| o}
    a.()
    a.(3)

### Multiple assignment
    foo = []
    foo[1], foo[2] = 1,2

### .foo=
    a = {}
    def a.foo=(v); end
    a.foo = 1

### With overwriting local variable
    raise = 1
    raise 'hello' rescue nil
    raise TypeError rescue nil
    raise TypeError rescue nil
    raise TypeError, 'hello' rescue nil
    raise(TypeError, 'hello') rescue nil

#### With illegal syntax (Ruby <2.5)
    raise = 1
    raise (TypeError, 'hello') rescue nil

### &. (Ruby 2.3+)
    nil&.foo
#>       xxx
    42&.to_s # missed_empty_branch
#>
    0&.to_s&.to_i&.nonzero?&.foo(42)&.to_i.nil?
#>                           xxx-xx-  xxxx
    raise&.to_s
#>       xxxxxx

#### &.= (branch_like_25:2.7)
    nil&.foo = bar
#>       xxx x xxxx
    nil&.foo = *bar
#>       xxx x xxxx

#### Inside of a block
    1.times do
      123&.to_s # missed_empty_branch
    end

### odd error case
    def dummy_method2(*)
      dummy_method 42
    end
    assert_equal 42, dummy_method2

### operators and parens
    2 + 2
    assert !!(current_ast.covered_code.instrument_source =~ /2 \+ 2/)
