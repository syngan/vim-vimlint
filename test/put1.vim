" @ERR []
function! g:hoge()
  let path = "."
  silent 0put =getpos(path)
endfunction
