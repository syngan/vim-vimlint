" @ERR ["EVL104"]
function! s:hoge(f)
    if a:f
      if has_key(a:f, "1")
        let value = 1
      elseif 2 < len(a:f)
        let value = 2
      endif
      if a:f ==# '^'
        let value = 3
      endif
      echo value
    endif
endfunction
