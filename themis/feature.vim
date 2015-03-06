scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:suite = themis#suite('feature')
let s:assert = themis#helper('assert')

function! s:suite.feature()
  let dict = vimlint#feature#list()
  for key in keys(dict)
    call s:assert.not_match(key, '[A-Z]', key)
  endfor
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
