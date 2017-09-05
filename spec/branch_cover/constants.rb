### Global

    ::String

### Unscoped

    String

### Scoped

    Float::INFINITY
    ::Float::INFINITY

### Undefined
#### Scoped

    begin
      Float::INFINITY::Nope::Neither
#>                         xxxxxxxxx
    rescue
    end

#### Global

    begin
      ::Foo
      "nope"
#>X
    rescue
    end

### Skipped Global

    4 ||  ::Foo
#>        --xxx
