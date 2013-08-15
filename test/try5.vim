" @ERR []
function! g:hoge(expr)
  try
    return eval(a:expr)
  finally
	echo "end"
  endtry
endfunction
