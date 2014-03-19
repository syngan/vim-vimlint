" @ERR []
function! Hoge()
  let path = "."
  silent 0put =getpos(path)
endfunction
