### Empty rescue clause
#### With raise

    begin
      raise
    rescue
    end

    a = begin
      raise
      "foo"
#>X
    rescue
    end
    assert a.nil?

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
#>  xxxxxx                    -
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
#>  xxxxxx                    -           xx xxx
      "not here"
#>X
    rescue Exception => bar
      "here"
    rescue SyntaxError, TypeError => baz
#>X
      "nor here"
#>X
    end

#### Without raise
    begin
      :dont_raise
    rescue NotImplementedError => foo
#>X
      "not here"
#>X
    end

#### Nested
    begin
      begin
        raise TypeError
        "not here"
#>X
      rescue NotImplementedError => foo
#>    xxxxxx                     xx xxx
      end
      "not here either"
#>X
    rescue TypeError => baz
      "here"
    end
    "here too"

### Modifier
    "here" rescue "not here"
#>         xxxxxx xxxxxxxxxx

    [raise, "here"] rescue "here"
#>        - xxxxxx

#### Multiple... <vomits>
    "here" rescue "not here" rescue "nor here"
#>         xxxxxx xxxxxxxxxx xxxxxx xxxxxxxxxx

    [raise, "not here"] rescue "here" rescue "nor here"
#>        - xxxxxxxxxx                xxxxxx xxxxxxxxxx

    [raise, "not here"] rescue [raise, "nor here"] rescue "here"
#>        - xxxxxxxxxx               - xxxxxxxxxx
