def foo(should_raise = nil, *)
  raise if should_raise
end

foo(foo(true, foo(foo))) rescue nil

