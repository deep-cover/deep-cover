### Empty rescue clause
#### With raise

    begin
      raise
    rescue
    end

    begin
      raise
      "foo"
#>X
    rescue
    end

#### Without raise

    begin
      :dont_raise
    rescue
#>X
    end

### With exception list, but no assignment

    begin
      raise
      "foo"
#>X
    rescue NotImplementedError, TypeError
#>  xxxxxx
    rescue Exception
      "here"
    rescue SyntaxError, TypeError
#>X
      "not here"
#>X
    end

#### Without raise
    begin
      :dont_raise
    rescue NotImplementedError
#>X
    end

### With assigned exception list
    begin
      raise
      "foo"
#>X
    rescue NotImplementedError, TypeError => foo
#>  xxxxxx                                xxxxxx
    rescue Exception => bar
      "here"
    rescue SyntaxError, TypeError => baz
#>X
      "not here"
#>X
    end

#### Without raise
    begin
      :dont_raise
    rescue NotImplementedError => foo
#>X
    end

