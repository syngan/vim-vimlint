" @ERR []
" issue #76
function! Test() range
  call append(a:lastline, "test")
endfunction
function! Test2() range
  call append(a:firstline, "test")
endfunction

