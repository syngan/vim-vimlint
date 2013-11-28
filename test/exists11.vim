" @ERR ["EVL101"]
function! g:hoge()
	let s:a = 0
	if s:a
		echo s:a
	elseif !exists("foo")
		echo foo
	else
		echo foo
	endif
endfunction
