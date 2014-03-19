" @ERR ["EVL104"]
function! Hoge()
  if 1 == 1
    let a = 1
    echo a
  else
    let b = 2
    echo b
  endif
  echo b
endfunction
