" @ERR ["EVL102"]
function! g:hoge()
  for a in [1,2,3]
    if 1
      let b = a
      break
    endif
  endfor
endfunction
