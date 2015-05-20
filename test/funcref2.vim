" @ERR ["EVL111"]
function! Hoge()
  let Fn = function('max')
  echo l:Fn([1,2,3])
endfunction
