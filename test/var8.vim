" @ERR []
function Foo()
  " #52
  set errorformat=%m
  let foo=['file']
  cexpr foo
endfunction
