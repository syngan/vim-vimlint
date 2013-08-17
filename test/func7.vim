" @ERR ["EVL104"]
function! g:hoge()
  if 1
    let a = 1
    echo a
  else
    let b = 2
    echo b
  endif
  echo b
endfunction
