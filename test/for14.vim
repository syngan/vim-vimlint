" @ERR ["EVL102"]
function! g:hoge(v)
  for a in a:v
    if a == 1
      let b = a
      break
    endif
  endfor
endfunction
