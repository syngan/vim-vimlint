" @ERR ["ELV104"]
function! g:hoge()
  for b in []
    let a = 1
    echo a
    unlet b
  endfor
  echo a 
endfunction
