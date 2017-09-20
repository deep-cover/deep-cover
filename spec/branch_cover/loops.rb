### For loop
    for i in [1,2,3,4,5]
      "here"
    end

#### With multiple assignments
    for i, j in [[1,2], [3,4]]
      "here"
    end

#### With break
    for i in [1,2,3,4,5]
      "here"
      break "here"
      "not here"
#>X
    end

#### With next
    for i in [1,2,3,4,5]
      "here"
      next  "here"
      "not here"
#>X
    end

#### With raise in iterable
    begin
      for i in ["here", raise, "not here"]
#>    xxx x xx                 xxxxxxxxxx
        "not_here"
#>X
      end
#>X
    rescue
    end

#### Never entering
    for i in []
#>      x
      "not here"
#>X
    end
