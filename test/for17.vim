" @ERR ["EVL102"]
function! g:hoge(pos)
  for p in a:pos
    if p
      for j in range(3)
        let v = j
      endfor
      continue
    endif
    for j in range(2)
      let v = j
    endfor
  endfor
endfunction 


