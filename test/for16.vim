" @ERR ["EVL102"]
function! Hoge(pos)
  for p in a:pos
    if p
      for j in range(1)
        let v = j
      endfor
	  continue
    endif
  endfor
endfunction
