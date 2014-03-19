" @ERR []
function! Hoge()
  for a in [1,2,3] 
    try
      let pos = getpos('.')
    catch
      let pos = -1
    finally
      echo 123
    endtry

    if pos + a < 0
      continue
    endif
    unlet a
  endfor
endfunction
