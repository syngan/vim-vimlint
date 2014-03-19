" @ERR []
function! Hoge()
  try
    let a = 1
    return 2
  finally
    echo a
  endtry
endfunction
