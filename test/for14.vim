" @ERR ["EVL102"]
function! Hoge(v)
  for a in a:v
    if a == 1
      let b = a
      break
    endif
  endfor
endfunction
