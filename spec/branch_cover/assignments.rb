### +=

    foo = 1
    foo += 2
    (foo += :oops) rescue nil
#>       xx
    (@@foo += 0) rescue nil
#>         xxxx
    (foo.bar += 42) rescue nil
#>           xxxxx
    (42.to_s += 'x') rescue nil
#>           xx

### ||=

    foo = false
    foo ||= true
    foo ||= true
#>          xxxx
    (foo.bar ||= 42) rescue nil
#>           xxxxxx
    foo = {}; def foo.bar; false; end
    (foo.bar ||= 42) rescue nil
#>           xxx

### &&=

    foo = true
    foo &&= false
    foo &&= false
#>          xxxxx
    (foo.bar &&= 42) rescue nil
#>           xxxxxx
    foo = {}; def foo.bar; true; end
    (foo.bar &&= 42) rescue nil
#>           xxx

### Multiple

    a, b, c = 1
    foo = {}; foo[:a], bar = 1
    o = Object.new; def o.foo=(x); end; a, o.foo, c = 1
    a, (b, c, (d, *e)) = 1

#### raising on the value side
    (a, b, c = 1, raise, 2) rescue nil
#>   xxxxxxxxx           x

#### raising when assigning
    foo = {}; (foo[:a], foo.bar, c = 1, 2, 3; :nope) rescue nil
#>                               x            xxxxx
