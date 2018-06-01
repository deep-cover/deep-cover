### +=

    foo = 1
    foo += 2
    (foo += :oops) rescue nil
#>  -    xx      -
    (@@foo += 0) rescue nil
#>  -      xxxx-
    (foo.bar += 42) rescue nil
#>  -        xxxxx-
    (42.to_s += 'x') rescue nil
#>  -        xx    -

### ||=

    foo = false
    foo ||= true
    foo ||= true
#>          xxxx
    (foo.bar ||= 42) rescue nil
#>  -        xxxxxx-
    foo = {}; def foo.bar; false; end
    (foo.bar ||= 42) rescue nil
#>  -        xxx   -

### []=
    foo = []
    foo[1] = 2
    foo[1] ||= 2
#>             x
    foo[2] ||= 3
    foo[2] &&= 4
    foo[3] &&= 2
#>             x


#### Constant (!Jruby)

    OR_EQUAL ||= 42
    OR_EQUAL ||= 42
#>               xx
    Object.send(:remove_const, 'OR_EQUAL')
    ::OR_EQUAL2 ||= 42
    Object.send(:remove_const, 'OR_EQUAL2')
    String::OR_EQUAL3 ||= 42
    String.send(:remove_const, 'OR_EQUAL3')
    (String::OR_EQUAL4 ||= raise; 42) rescue nil
#>  -                  xxx      - xx-

#### Constant in raising scope (!JRuby)

    (Nope::OR_EQUAL5 ||= 42) rescue nil
#>  -    xxxxxxxxxxxxxxxxxx-

### &&=

    foo = true
    foo &&= false
    foo &&= false
#>          xxxxx
    (foo.bar &&= 42) rescue nil
#>  -        xxxxxx-
    foo = {}; def foo.bar; true; end
    (foo.bar &&= 42) rescue nil
#>  -        xxx   -

#### Constant (!Jruby)

    (AND_EQUAL &&= 42) rescue nil
#>  -          xxxxxx-
    AND_EQUAL = true; AND_EQUAL &&= 42
    self.class.send(:remove_const, :AND_EQUAL)
    ::AND_EQUAL2 = true; ::AND_EQUAL2 &&= 42
    (String::AND_EQUAL3 &&= 42) rescue nil
#>  -                   xxxxxx-
    String::AND_EQUAL3 = true; String::AND_EQUAL3 &&= 42
    String.send(:remove_const, :AND_EQUAL3)
    String::AND_EQUAL5 = true; (String::AND_EQUAL5 &&= raise; 42) rescue nil
#>                           - -                   xxx      - xx-
    (Nope::AND_EQUAL6 &&= 42) rescue nil
#>  -    xxxxxxxxxxxxxxxxxxx-

#### Constant (!JRuby)

    String::AND_EQUAL4 = false; String::AND_EQUAL4 &&= 42
#>                            -                        xx

### Multiple

    a, b, c = 1
    foo = {}; foo[:a], bar = 1
    o = Object.new; def o.foo=(x); end; a, o.foo, c = 1
    a, (b, c, (d, *e)) = 1
    MULTIPLE, String::MULTIPLE_SCOPED, ::MULTIPLE_GLOBAL = 1

### Multiple with raise

    a, dummy_method.foo, c = 1 rescue nil
#>   -                 - x
    a, raise.foo, c = 1
#>   -      xxxx- x

#### Empty splat

    a, b, * = nil

#### raising on the value side
    (a, b, c = 1, raise, 2) rescue nil
#>  -x- x- xxx  -      - x-
    (MULTIPLE_R, String::MULTIPLE_SCOPED_R = 1, raise, 2) rescue nil
#>  -xxxxxxxxxx- xxxxxxxxxxxxxxxxxxxxxxxxxxx  -      - x-

#### raising when assigning
    foo = {}; (foo[:a], foo.bar, c = 1, 2, 3; :nope) rescue nil
#>          - -       -        - x    -  -  - xxxxx-
    ((a, (b, *c.foo), d) = 1) rescue nil
#>  -- - - -       -- x-    -
    (MULTIPLE_RA, String::Nope::MULTIPLE_SCOPED_RA, MULTIPLE_RA2 = 1, 2) rescue nil
#>  -           -             xxxxxxxxxxxxxxxxxxxx- xxxxxxxxxxxx    -  -

#### self setters

    o = Object.new; class << o; def foo=(x); end; private; def bar=(x); end; end
    o.instance_eval do
      a, o.foo, c = 1
      a, self.foo, self.bar, c = 1
      (a, $o.foo, self.nope, self.bar, c = 1) rescue nil
#>    - -       - xxxxxxxxx- xxxxxxxx- x    -
    end
#>  ---

#### self setters approximation. answers can be overly conservative.

    o = Object.new; class << o; def foo=(x); end; end
    o.instance_eval do
      (a, self.foo, raise.bar, c = 1) rescue nil
#>    - -         -      xxxx- x    -
      (a, self.foo, self.nope, c = 1) rescue nil
#>    -x- xxxxxxxx- xxxxxxxxx- x    -
    end
#>  ---
