" @ERR []
" ignore comment
function! g:hoge()
    for lnum in [1,2,3]
        if lnum == 1
            continue    " Skip blank line.
        endif
		unlet lnum
    endfor
endfunction "}}}

