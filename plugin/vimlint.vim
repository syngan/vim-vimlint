if exists('g:loaded_vimlint')
  finish
endif
let g:loaded_vimlint = 1

let s:save_cpo = &cpo
set cpo&vim

"-nargs=*    Any number of arguments are allowed (0, 1, or many),
command! -nargs=*
\ -complete=customlist,vimlint#util#complete
\ VimLint call vimlint#command(<q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
