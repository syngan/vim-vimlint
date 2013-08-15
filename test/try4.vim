" @ERR ["ELV104"]
function! g:hoge()
  if 1
    let env_ev = 1
    let len_env = 2
  else
    let len_env = 0
  endif

  if len_env != 0 && env_ev == 5
    echo 123
  endif
endfunction
