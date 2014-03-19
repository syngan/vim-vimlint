" @ERR []
function! Hoge(expr)
  try
    return eval(a:expr)
  finally
	echo "end"
  endtry
endfunction
