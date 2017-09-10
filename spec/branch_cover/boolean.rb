### Simple if
    if 1 || 2
#>          x
      "hello"
    else
      "never"
#>X
    end
    "after"

    dummy_method(1 || 2)
#>                    x
    dummy_method(1 && 2)

    begin
      dummy_method(1 && raise)
#>    xxxxxxxxxxxxx          x
    rescue
    end

