" @ERR []
function! g:hoge()
	let a = 2
	let b = eval('a')
	echo b
endfunction
