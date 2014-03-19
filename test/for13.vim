" @ERR []
function! Hoge()
  for a in [1,2,3]
    let b = a
  endfor
  echo b
endfunction
