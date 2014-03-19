" @ERR ["EVL104"]
function! Hoge(a)
  if a:a == 1
    if a:a
	  let c = 1
	  echo c
	else
      let b = 1
	  echo b
    endif
    echo b
  endif
endfunction
