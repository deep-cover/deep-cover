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
    raise (TypeError, 'hello') rescue nil
