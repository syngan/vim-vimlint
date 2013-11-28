" @ERR ["EVL101"]
function! g:hoge()
	let s:a = 1
	if s:a
		echo foo
	elseif !exists("foo")
		echo "not through"
	else
		echo foo
	endif
endfunction
