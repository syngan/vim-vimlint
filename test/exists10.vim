" @ERR []
function! Hoge()
	let s:a = 0
	if s:a
		echo s:a
	elseif !exists("foo")
		echo "not through"
	else
		echo foo
	endif
endfunction
