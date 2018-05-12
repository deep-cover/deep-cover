### For loop
    for i in [1,2,3,4,5]
      "here"
    end

#### With empty body
    for i in [1,2,3]
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
    for i in ["here", raise, "not here"]
#>  xxx x xx        -      - xxxxxxxxxx
      "not_here"
#>X
    end
#>X

#### Never entering
    for i in []
#>      x
      "not here"
#>X
    end


### While loop
    i = 0
    while i < 5
      b = i
      i += 1
    end

#### Empty body
    while false
    end

#### With break
    while true
      "here"
      break "here"
      "not here"
#>X
    end

#### With next
    i = 0
    while i < 5
      i += 1
      "here"
      next  "here"
      "not here"
#>X
    end

#### With raise in condition
    while ("here"; raise; "not here")
#>  xxxxx -      -      - xxxxxxxxxx-
      "not_here"
#>X
    end
#>X

#### Never entering
    while false
      "not here"
#>X
    end


### While modifier
    i = 0
    i += 1 while i < 5

#### With break
    ("here"; break "here"; "not here") while true
#>  -      -             - xxxxxxxxxx-

#### With next
    i = 0
    (i += 1; next "here"; "not here") while i < 5
#>  -      -            - xxxxxxxxxx-

#### Never entering
    "not here" while false
#>  xxxxxxxxxx


### Until loop
    i = 0
    until i >= 5
      b = i
      i += 1
    end

#### Empty
    until true
    end

#### With break
    until false
      "here"
      break "here"
      "not here"
#>X
    end

#### With next
    i = 0
    until i >= 5
      i += 1
      "here"
      next  "here"
      "not here"
#>X
    end

#### Never entering
    until true
      "not here"
#>X
    end


### Until modifier
    i = 0
    i += 1 until i >= 5

#### With break
    ("here"; break "here"; "not here") until false
#>  -      -             - xxxxxxxxxx-

#### With next
    i = 0
    (i += 1; next "here"; "not here") until i >= 5
#>  -      -            - xxxxxxxxxx-

#### With raise in condition
    until ("here"; raise; "not here")
#>  xxxxx -      -      - xxxxxxxxxx-
      "not_here"
#>X
    end
#>X

#### Never entering
    "not here" until true
#>  xxxxxxxxxx
