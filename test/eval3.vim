" @ERR []
function! g:hoge(c)
	let b = eval('a:c')
	echo b
endfunction
