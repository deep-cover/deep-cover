### Without rescue
#### With raise

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

### Empty parts
#### With empty begin
    begin

    else
      "here"
    end

    begin

    rescue
#>X
      "not here"
#>X
    else
      "here"
    end
