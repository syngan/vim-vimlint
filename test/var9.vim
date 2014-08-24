" @ERR []
function Foo(v)
  " #28
  echo a:v
  let a:v[2:3] = [1,2]
endfunction
