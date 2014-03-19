" @ERR ["EVL101"]
function! Hoge()
  let a = 1
  echo a
  unlet! a
  echo a
endfunction
