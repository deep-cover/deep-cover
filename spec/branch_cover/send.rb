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
    foo.[]=(3, 4)
    foo.[]= 3, 4

### .()
    a = proc {|o| o}
    a.()
    a.(3)

### Multiple assignment
    foo = []
    foo[1], foo[2] = 1,2
