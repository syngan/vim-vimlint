" @ERR []
function! s:Hoge()
  let s:a = 1
  call s:Goo()
  unlet s:a
endfunction

function! s:Goo()
  echo s:a
endfunction
