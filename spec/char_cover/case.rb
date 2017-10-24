### Case with evaluated
    case 1
    when 0
      "not here"
#>X
    when 1
      "here"
    when 2
#>X
      "not here"
#>X
    end

#### Without entering when
    case 1
    when 0
      "not here"
#>X
    end

#### With raise in case evaluated
    case [1, raise, "not here"]
#>  xxxx   -      - xxxxxxxxxx
    when 0
#>X
      "not here"
#>X
    end
#>  ---

#### With raise in when condition
    case 1
    when 0
      "not here"
#>X
    when raise
#>  xxxx
      "not here"
#>X
    when 1
#>X
      "not here"
#>X
    end

#### with raise in when body
    case 1
    when 0
      "not here"
#>X
    when 1
      raise
      "not here"
#>X
    when 2
#>X
      "not here"
#>X
    end

#### with multi part when condition
    case 1
    when 0, 10, 20
      "not here"
#>X
    when -1, 1, 1000
#>         -  - xxxx
      "here"
    when -2, 2, 2000
#>X
      "not here"
#>X
    end

#### with raise in multi part when condition
    case 1
    when 0, 10, 20
      "not here"
#>X
    when -1, raise, 1000
#>         -      - xxxx
      "not here"
#>X
    when -2, 2, 2000
#>X
      "not here"
#>X
    end


### Case with evaluated and else
    case 1
    when 0
      "not here"
#>X
    when 1
      "here"
    when 2
#>X
      "not here"
#>X
    else
#>X
      "not here"
#>X
    end

#### Without entering when
    case 1
    when 0
      "not here"
#>X
    else
      "here"
    end

#### With raise in case evaluated
    case [1, raise, "not here"]
#>  xxxx   -      - xxxxxxxxxx
    when 0
#>X
      "not here"
#>X
    else
#>X
      "not here"
#>X
    end
#>  ---

#### With raise in when condition
    case 1
    when 0
      "not here"
#>X
    when raise
#>  xxxx
      "not here"
#>X
    when 1
#>X
      "not here"
#>X
    else
#>X
      "not here"
#>X
    end

#### with raise in when body
    case 1
    when 0
      "not here"
#>X
    when 1
      raise
      "not here"
#>X
    when 2
#>X
      "not here"
#>X
    else
#>X
      "not here"
#>X
    end

#### with raise in else body
    case 1
    when 0
      "not here"
#>X
    when 2
      "not here"
#>X
    else
      raise
      "not here"
#>X
    end

### With empty when body
    a = case 1
        when 1

        end
    assert a.nil?

### With failed ===
    obj = Object.new
    obj.define_singleton_method(:===) {|other| raise }

    case 1
    when obj, 1
#>          - x
      "not here"
#>X
    end

### With splat
    arr = [String, Symbol]
    case :hello
    # Interesting behavior when using splat in when, every condition gets evaluated
    # before any of them are compared to the target. So Integer is still evaluated.
    when Float, *arr, Integer
      "here"
    else
#>X
      "not here"
#>X
    end

#### With raising ===
    obj = Object.new
    obj.define_singleton_method(:===) {|other| raise }
    arr = [obj]
    case 1
    # Interesting behavior when using splat in when, every condition gets evaluated
    # before any of them are compared to the target. So Integer is still evaluated.
    when Float, *arr, Integer
      "not here"
#>X
    else
#>X
      "nor here"
#>X
    end
