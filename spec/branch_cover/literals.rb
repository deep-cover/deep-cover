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
### Complex (Ruby 2.1+)
    4.2i
### Symbols
    :hello
    :"he#{'l'*2}o"
    %s[hello]
    %i[hello world]
#### Raising (pending)
    dummy_method :"h#{3}l#{raise}o#{'2'}o#{:x}" rescue nil
#>  xxxxxxxxxxxx                 xxxxxxxxxxxxx

### Strings
    'world'
    "w#{0}rld"
    %{world}
    %q{w#{0}rld}
    %Q{w#{0}rld}

#### Raising (pending)
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

### Regexp
    /regexp/
    /re#{'g'}exp/i
    %r[regexp]
#### Raising (pending)
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
#>              x
### Hash
    {:a => 1, :b => 2}
    {a: 1, b: 2}
    {a: 1, **{b: 2}}
    {nil? => 1, :b => 2}
    {a: raise, :b => 2} rescue nil
#>             xx xx x
