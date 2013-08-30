" @ERR ["EVL102"]
function! g:hoge()
  for a in [1,2,3]
    if a == 1
      let b = a
    endif
  endfor
endfunction
