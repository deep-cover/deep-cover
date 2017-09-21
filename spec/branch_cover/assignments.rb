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

