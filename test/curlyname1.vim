" @ERR []
function! g:hoge(n)
  if a:n <= 1
    return 1
  endif
  let a = "hoge"
  return a:n * g:{a}(a:n-1)
endfunction
