### Global

    ::String
    ::SpecConstantsSampleGlobalAssignation = 1

### Unscoped

    String
    SpecConstantsSampleUnscopedAssignation = 1

### Scoped

    Float::INFINITY
    ::Float::INFINITY
    (Float)::INFINITY
    begin;Float;end::INFINITY
    DeepCover::SpecConstantsSampleScopedAssignation = 1
    ::DeepCover::SpecConstantsSampleScopedAssignation2 = 2
    (DeepCover)::SpecConstantsSampleScopedAssignation3 = 3
    begin;DeepCover;end::SpecConstantsSampleScopedAssignation4 = 4
    class Float
      self::INFINITY
      self::ANSWER = 42.0
      obj = {}; self::WHATEVER, foo, obj.nope, self::NOPE = nil rescue nil
#>            -               -    -         - xxxxxxxxxx
    end

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

#### Assigned with ||=

    DeepCover ||= 42
#>                xx
    DeepCover::SpecConstantsWithOr ||= 42
    DeepCover.send(:remove_const, :SpecConstantsWithOr)
    begin
      DeepCover::SpecConstantsSampleMissing::Assignation ||= 42
#>                                         xxxxxxxxxxxxx xxx xx
    rescue
    end
    DeepCover::SpecConstantsWithOrBis ||= raise
#>                                    xxx


### Skipped Global

    4 ||  ::Foo
#>        xxxxx
