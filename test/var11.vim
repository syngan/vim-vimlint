" @ERR []
function! Foo()
	let m = 0
	for r in range(5)
		unlet m
		let m = r
	endfor
	return m
endfunction


