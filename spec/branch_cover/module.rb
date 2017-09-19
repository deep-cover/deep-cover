### Empty module
    module A
    end.to_s

#### Explicit global module
    module ::B
    end.to_s

#### Scoped module
    module String::B
    end.to_s

### Raising
#### Module/Class clash
    module String
#>  xxxxxx
    end.to_s rescue nil
#>  xxxxxxxx

#### Invalid path
    module String::Foo::A
#>  xxxxxx            xxx
    end.to_s rescue nil
#>  xxxxxxxx

#### Invalid (longer) path
    module String::Foo::Bar::A
#>  xxxxxx            xxxxxxxx
    end.to_s rescue nil
#>  xxxxxxxx

#### Raise inside block
    module C
      42
      raise
      44
#>X
    end.to_s rescue nil
#>     xxxxx
