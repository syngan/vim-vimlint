" @ERR []
function! Hoge()
  let l:Fn = function('max')
  echo Fn([1,2,3])
endfunction
