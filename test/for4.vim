" @ERR []
function! g:hoge()
  for b in [1,2,3]
    if len([]) == 1
      let a = 1
    else
      break
    endif

    echo a+b
  endfor
endfunction
