### Without rescue
#### With raise (Ruby <2.6)

    begin
      raise
    else
#>X
      "not here"
#>X
    end rescue nil

#### With raise in else (Ruby <2.6)

    begin
      "here"
    else
      raise
      "not here"
#>X
    end

#### Without raise (Ruby <2.6)

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
#>X

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
#### With empty begin without rescue (Ruby <2.6)
    begin

    else
      "here"
    end


#### With empty begin with rescue
    begin

    rescue
#>X
      "not here"
#>X
    else
      "here"
    end
