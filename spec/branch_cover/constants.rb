### Global

    ::String
    ::SpecConstantsSampleGlobalAssignation = 1

### Unscoped

    String
    SpecConstantsSampleUnscopedAssignation = 1

### Scoped

    Float::INFINITY
    ::Float::INFINITY
    DeepCover::SpecConstantsSampleScopedAssignation = 1
    ::DeepCover::SpecConstantsSampleScopedAssignation = 1

### Undefined
#### Scoped

    begin
      Float::INFINITY::Nope::Neither
#>                         xxxxxxxxx
    rescue
    end

    begin
      DeepCover::SpecConstantsSampleMissing::Assignation = 1
#>                                         xxxxxxxxxxxxx x x
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
