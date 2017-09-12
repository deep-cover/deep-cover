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

### With assignment, but no exception list

    begin
      raise
      "foo"
#>X
    rescue => foo
      "here"
    end

#### Without raise
    begin
      :dont_raise
    rescue => foo
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

#### Nested
    begin
      begin
        raise TypeError
        "not here"
#>X
      rescue NotImplementedError
#>    xxxxxx
      end
      "not here either"
#>X
    rescue TypeError
      "here"
    end
    "here too"
