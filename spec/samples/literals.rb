### Range
    1...42
    1.0...4.2
    1..(2+2)
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
    42i
### Symbols
    :hello
    :"he#{'l'*2}o"
    %s[hello]
    %i[hello world]
### Strings
    'world'
    "w#{0}rld"
### Regexp
    /regexp/
    /re#{'g'}exp/i
    %r[regexp]
### Array
    [1, 2, 3]
    %w[hello world]
    [1, *nil?, 3]
    [1, *[2], 3]
    [1, raise, *nil?, 3] rescue nil
    [1, *raise, 3] rescue nil
### Hash
    {:a => 1, :b => 2}
    {a: 1, b: 2}
    {a: 1, **{b: 2}}
    {nil? => 1, :b => 2}
    {a: raise, :b => 2} rescue nil
