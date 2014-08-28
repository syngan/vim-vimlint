" @ERR []
function! Foo()
	echo get(a:, 0, 0)
	echo get(s:, 0, 0)
	echo get(g:, 0, 0)
	echo get(w:, 0, 0)
endfunction


