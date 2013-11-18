" @ERR ["EVL102"]
function! g:hoge()
  let path = "."
  silent 0put getpos(path)
endfunction
