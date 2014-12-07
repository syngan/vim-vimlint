" @ERR []
function! g:TEST2(motion)
  for x in a:motion
    if x == 1
      continue
    endif
    if x == 2
      return 3
    else
      return -x
    endif
  endfor
  return 0
endfunction

