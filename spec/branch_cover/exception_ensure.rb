### No rescue/else
#### With raise in begin
    begin
      begin
        raise
        "not here"
#>X
      ensure
        "here"
      end
    rescue
      "here"
    ensure
      "here"
    end

#### With raise in ensure
    begin
      begin
        "here"
      ensure
        "here"
        raise
        "not here"
#>X
      end
    rescue
      "here"
    ensure
      "here"
    end

#### Without raise
    begin
      "here"
    ensure
      "here"
    end


### With rescue
#### With rescued raise in begin
    begin
      raise
      "not here"
#>X
    rescue
      "here"
    ensure
      "here too"
    end

#### With unrescued raise in begin
    begin
      begin
        raise
        "not here"
#>X
      rescue TypeError
#>    xxxxxx
        "not here"
#>X
      ensure
        "here too"
      end
    rescue
    end

#### With raise in begin and rescue
    begin
      begin
        raise
        "not here"
#>X
      rescue
        raise
        "not here"
#>X
      ensure
        "here too"
      end
    rescue
    end

#### With raise in ensure
    begin
      begin
        "here"
      rescue
#>X
        "not here"
#>X
      ensure
        "here"
        raise
        "not here"
#>X
      end
    rescue
      "here"
    ensure
      "here"
    end

#### Without raise
    begin
      "here"
    rescue
#>X
      "not here"
#>X
    ensure
      "here too"
    end


### With rescue and else
#### With rescued raise in begin
    begin
      raise
      "not here"
#>X
    rescue
      "here"
    else
#>X
      "nor here"
#>X
    ensure
      "here too"
    end

#### With unrescued raise in begin
    begin
      begin
        raise
        "not here"
#>X
      rescue TypeError
#>    xxxxxx
        "nor here"
#>X
      else
#>X
        "nor here"
#>X
      ensure
        "here too"
      end
    rescue
    end

#### With raise in else
    begin
      begin
        "here"
      rescue
#>X
        "not here"
#>X
      else
        raise
        "nor here"
#>X
      ensure
        "here too"
      end
    rescue
    end

#### Without raise
    begin
      "here"
    rescue
#>X
      "not here"
#>X
    else
      "here too"
    ensure
      "here again"
    end

### Empty parts
#### With empty begin
    begin

    rescue
#>X
      "not here"
#>X
    else
      "here"
    ensure
      "here too"
    end


#### With empty rescue
    begin
      "here"
    rescue
#>X
    else
      "here"
    ensure
      "here too"
    end

#### With empty rescue
    begin
      "here"
    rescue
#>X
      "not here"
#>X
    else

    ensure
      "here too"
    end

#### With empty ensure
    begin
      "here"
    rescue
#>X
      "not here"
#>X
    else
      "here"
    ensure

    end

#### With everything empty but ensure
    begin

    rescue
#>X
    else

    ensure
      "here"
    end

#### With everything empty
    begin

    rescue
#>X
    else

    ensure

    end
