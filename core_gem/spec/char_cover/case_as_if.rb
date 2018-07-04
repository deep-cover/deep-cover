### Case without evaluated
    case # missed_empty_branch
    when 1 == 0
      "not here"
#>X
    when "hi".index("i")
      "here"
    when 1 == 2
#>X
      "not here"
#>X
    end

#### Without entering when
    case
    when 1 == 0
      "not here"
#>X
    end

#### With raise in when condition
    case # missed_empty_branch
    when 1 == 0
      "not here"
#>X
    when 1 == raise
#>  xxxx   xx
      "not here"
#>X
    when 1 == 1
#>X
      "not here"
#>X
    end

#### with raise in when body
    case # missed_empty_branch
    when 1 == 0
      "not here"
#>X
    when 1 == 1
      raise
      "not here"
#>X
    when 1 == 2
#>X
      "not here"
#>X
    end

#### with multi part when condition
    case # missed_empty_branch
    when 1 == 0, 1 == 10
      "not here"
#>X
    when 1 == -1, 1 == 1, 1 == 1000
#>              -       - x xx xxxx
      "here"
    when 1 == -2, 1 == 2
#>X
      "not here"
#>X
    end

#### with raise in multi part when condition
    case # missed_empty_branch
    when 1 == 0, 1 == 10
      "not here"
#>X
    when 1 == -1, raise, 1 == 20
#>              -      - x xx xx
      "not here"
#>X
    when 1 == -2, 1 == 2
#>X
      "not here"
#>X
    end


### Case with evaluated and else
    case # missed_empty_branch
    when 1 == 0
      "not here"
#>X
    when 1 == 1
      "here"
    when 1 == 2
#>X
      "not here"
#>X
    end

#### Without entering when
    case
    when 1 == 0
      "not here"
#>X
    else
      "here"
    end

#### With raise in when condition
    case
    when 1 == 0
      "not here"
#>X
    when raise
#>  xxxx
      "not here"
#>X
    when 1 == 1
#>X
      "not here"
#>X
    else
#>X
      "not here"
#>X
    end

#### with raise in when body
    case
    when 1 == 0
      "not here"
#>X
    when 1 == 1
      raise
      "not here"
#>X
    when 1 == 2
#>X
      "not here"
#>X
    else
#>X
      "not here"
#>X
    end

#### with raise in else body
    case
    when 1 == 0
      "not here"
#>X
    when 1 == 2
      "not here"
#>X
    else
      raise
      "not here"
#>X
    end

#### with empty else
    case
    when 1 == 0
      "not here"
#>X
    when 1 == 2
      "not here"
#>X
    else
    end
