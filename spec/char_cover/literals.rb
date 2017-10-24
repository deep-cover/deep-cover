### Range
    1...42
    1.0...4.2
    1..(2+2)
    raise..42 rescue nil
#>         xx
    'a'..'z'
    a = 42
    1..a
### Boolean
    nil
    false
    true
### Numbers
    1_234
    1.23e4
### Rational (Ruby 2.1+)
    4.2r
### Complex (Ruby 2.1+)
    42i
    4.2ri
### Symbols
    :hello
    :"he#{'l'*2}o"
    %s[hello]
    %i[hello world]
#### Raising
    dummy_method :"h#{3}l#{raise}o#{'2'}o#{:x}" rescue nil
#>  xxxxxxxxxxxx                 xxxxxxxxxxxxx

### Strings
    'world'
    "w#{0}rld"
    %{world}
    %q{w#{0}rld}
    %Q{w#{0}rld}
    "hello#$1"

#### Raising
    dummy_method "oo#{raise}ps#{:never}" rescue nil
#>  xxxxxxxxxxxx            xxxxxxxxxxx
    dummy_method """
#>  xxxxxxxxxxxx
    multi
    #{raise}
    line
#>X
    #{:never}" rescue nil
#>  xxxxxxxxx

### Heredocs
#### Raising
    insane = [<<-ONE, 1, <<-TWO, 2, <<-THREE, 3, <<-FOUR] rescue nil
#>                                            x  xxxxxxx
      the first thing
      with many lines
    ONE
      the second thing with one line
    TWO
      and the third thing
      that raises #{raise}!
#>                        x
    THREE
      fouth for safety
#>X
    FOUR
#>X

#### Empty
    [<<-ONE, 1, <<-TWO, 2]
    ONE

    TWO

### Regexp
    /regexp/
    /re#{'g'}exp/i
    /regexp/mi
    %r[regexp]
#### Raising
    dummy_method /re#{raise}g#{'e'}p#{:x}/i rescue nil
#>  xxxxxxxxxxxx            xxxxxxxxxxxxx x

### Array
    [1, 2, 3]
    %w[hello world]
    [1, *nil?, 3]
    [1, *[2], 3]
    [1, raise, *nil?, 3] rescue nil
#>             xxxxx  x
    [1, *raise, 3] rescue nil
#>      x       x
### Hash
    {:a => 1, :b => 2}
    {a: 1, b: 2}
    {a: 1, **{b: 2}}
    {a: raise, **{b: 2}} rescue nil
#>             xxxxx xx
    {a: 1, **{b: raise}} rescue nil
#>         xx
    {nil? => 1, :b => 2}
    {a: raise, :b => 2} rescue nil
#>             xx xx x

### Xstr
    `echo 'abc'`.to_s
    (`echoqweqwe #{raise}`) rescue nil
#>   x                   x

#### raising (!JRuby)
    (`echoqweqwe`.to_s) rescue nil
#>               xxxxx
