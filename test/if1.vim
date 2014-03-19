" @ERR ["EVL104"]
function! Hoge()
  if len([1,2,3]) == 0
    let a  = 3
  else
    echo "1+2"
  endif
  echo a
endfunction
