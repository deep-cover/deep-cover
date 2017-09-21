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
