" @ERR ["EVL104"]
function! Hoge(v)
  for b in a:v
    let a = 1
    echo a . b
    unlet b
  endfor
  echo a 
endfunction
