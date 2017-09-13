### Without rescue
#### With raise (pending)

    # The result we want for the else is not obvious.
    # Either way (not executed or not executable), it is hard to do because the else,
    # when there are no rescue in the begin, is only part of the kwbegin, so it is part
    # of the sme proper_range as the begin and the end. So right now, we can only show
    # it as executed.

    begin
      begin
        raise
      else
#>X
        "not here"
#>X
      end
    rescue
    end

    begin
      "hi"
    end
    begin
      begin
        "here"
      else
        raise
        "not here"
#>X
      end
    rescue
    end

#### Without raise

    begin
      "here"
    else
      "here too"
    end

### With rescue
#### With raise

    begin
      raise
      "foo"
#>X
    rescue
      "here"
    else
#>X
      "not here"
#>X
    end

    begin
      raise
      "foo"
#>X
    rescue
      "here"
    else
#>  ----

    end

#### Without raise
    begin
      "foo"
    rescue
#>X
      "not here"
#>X
    else
      "here"
    end
