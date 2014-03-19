" @ERR []
function! Hoge()
  let a = 1
  try
    return 2
  finally
    echo a
  endtry
endfunction

