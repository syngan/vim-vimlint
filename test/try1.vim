" @ERR []
function! Hoge()
  try
    echo 1 
  catch
    return
  endtry
  echo 2
endfunction
