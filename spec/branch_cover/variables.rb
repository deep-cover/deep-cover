### Local
    foo = 1
    dummy_method foo

#### Raise
    begin
      bar = raise
#>    xxx x
    rescue
    end

    begin
      dummy_method raise, bar
#>    xxxxxxxxxxxx        xxx
    rescue
    end


### Instance
    @foo = 1
    dummy_method @foo

#### Raise
    begin
      @bar = raise
#>    xxxx x
    rescue
    end

    begin
      dummy_method raise, @bar
#>    xxxxxxxxxxxx        xxxx
    rescue
    end


### Class
    @@foo = 1
    dummy_method @@foo

#### Raise
    begin
      @@bar = raise
#>    xxxxx x
    rescue
    end

    begin
      dummy_method raise, @@bar
#>    xxxxxxxxxxxx        xxxxx
    rescue
    end


### Global
    $_some_nowhere_global = 1
    dummy_method $_some_nowhere_global

#### Raise
    begin
      $_some_nowhere_global = raise
#>    xxxxxxxxxxxxxxxxxxxxx x
    rescue
    end

    begin
      dummy_method raise, $_some_nowhere_global
#>    xxxxxxxxxxxx        xxxxxxxxxxxxxxxxxxxxx
    rescue
    end
