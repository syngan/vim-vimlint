" @ERR []
function! g:TEST()
  for x in [[0,-2,-1]]
    if len(x) > 2
      continue
    endif
    return 1
  endfor

  return
endfunction
