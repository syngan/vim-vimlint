" @ERR []
function! g:hoge()
  while 1
    let a = 1
    break
  endwhile

  echo a
endfunction
