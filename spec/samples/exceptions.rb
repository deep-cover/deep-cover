begin
  raise
rescue
end

begin
  :dont_raise
rescue
end

begin
  raise
rescue Exception => foo
end

begin
  raise NotImplementedError
rescue SyntaxError => foo
  "nope"
rescue Exception => foo
  "yes"
end
