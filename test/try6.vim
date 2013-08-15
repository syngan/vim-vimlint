" @ERR []
function! g:hoge()
  let a = 1
  try
    return 2
  finally
    echo a
  endtry
endfunction

