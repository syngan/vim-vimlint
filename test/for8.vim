" @ERR []
function! g:hoge()
  for b in [1,2,3]
    if len([]) == 0
      let a = 1
      break
    endif

    let a = 2
    echo a
    unlet b
  endfor
endfunction
