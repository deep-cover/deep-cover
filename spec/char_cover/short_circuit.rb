### ||
    dummy_method(1 || 42)
#>              -     xx-
    dummy_method(nil || 42)

#### Raising first
    dummy_method(raise || 42)
#>  xxxxxxxxxxxx-         xx-

#### Raising second
    dummy_method(nil || raise)
#>  xxxxxxxxxxxx-            -

### &&
    dummy_method(1 && 42)
    dummy_method(nil && 42)
#>              -       xx-

#### Raising first
    dummy_method(raise && 42)
#>  xxxxxxxxxxxx-         xx-

#### Raising second
    dummy_method(42 && raise)
#>  xxxxxxxxxxxx-           -
