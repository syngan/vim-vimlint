" @ERR []
" issue60
function! s:gettest(a)
  if a:a
    let afo = 1
  endif
  return get(l:, 'afo')
endfunction
