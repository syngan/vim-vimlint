" @ERR []
function! Hoge(a)
  if a:a == 1
    if a:a
      let b = 1
    else
      let b = 2
    endif
    echo b
  endif
endfunction

" vim:set et ts=2 sts=2 sw=2 tw=0 foldmethod=marker:
