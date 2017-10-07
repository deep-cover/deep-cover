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
    MULTIPLE, String::MULTIPLE_SCOPED, ::MULTIPLE_GLOBAL = 1

#### raising on the value side
    (a, b, c = 1, raise, 2) rescue nil
#>   xxxxxxxxx           x
    (MULTIPLE_R, String::MULTIPLE_SCOPED_R = 1, raise, 2) rescue nil
#>   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx           x

#### raising when assigning
    foo = {}; (foo[:a], foo.bar, c = 1, 2, 3; :nope) rescue nil
#>                               x            xxxxx
    ((a, (b, *c.foo), d) = 1) rescue nil
#>                    x
    (MULTIPLE_RA, String::Nope::MULTIPLE_SCOPED_RA, MULTIPLE_RA2 = 1, 2) rescue nil
#>                            xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

#### self setters

    o = Object.new; class << o; def foo=(x); end; private; def bar=(x); end; end
    o.instance_eval do
      a, o.foo, c = 1
      a, self.foo, self.bar, c = 1
      (a, $o.foo, self.nope, self.bar, c = 1) rescue nil
#>                xxxxxxxxxxxxxxxxxxxxxx
    end
#>  ---

#### self setters approximation. answers are overly conservative.

    o = Object.new; class << o; def foo=(x); end; end
    o.instance_eval do
      (a, self.foo, raise.bar, c = 1) rescue nil
#>     xxxxxxxxxxxxxxxxxxxxxxxxx
      (a, self.foo, self.nope, c = 1) rescue nil
#>     xxxxxxxxxxxxxxxxxxxxxxxxx
    end
#>  ---
