" @ERR []
function! g:Test(x)
  return substitute("hogehogehoge", "og", '\=a:x', 'g')
endfunction
