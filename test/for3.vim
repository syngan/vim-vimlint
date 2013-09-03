" @ERR ["EVL104"]
function! g:hoge(v)
  for b in a:v
    let a = 1
    echo a . b
    unlet b
  endfor
  echo a 
endfunction
