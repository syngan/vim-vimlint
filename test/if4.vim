" @ERR ["EVL104"]
function! g:hoge()
  if 1 == 1
    if executable('curl')
      let cmd = 'curl --fail -s -o'
    elseif executable('wget')
      let cmd = 'wget -q -O'
    endif

    echo cmd
  endif

endfunction
