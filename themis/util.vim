scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:suite = themis#suite('util')
let s:assert = themis#helper('assert')

function! s:suite.stol()
  call s:assert.equals(vimlint#util#stol(''), [])
  call s:assert.equals(vimlint#util#stol('a'), ['a'])
  call s:assert.equals(vimlint#util#stol('a b c'), ['a', 'b', 'c'])
  call s:assert.equals(vimlint#util#stol('"a b" c'), ['a b', 'c'])
  call s:assert.equals(vimlint#util#stol("'a b' c"), ['a b', 'c'])
  call s:assert.equals(vimlint#util#stol('"a '' b" c'), ['a '' b', 'c'])
endfunction

function! s:suite.parse_cmdline()
  call s:assert.equals(vimlint#util#parse_cmdline('A B', {}), [['A', 'B'], {}])
  call s:assert.equals(vimlint#util#parse_cmdline('-output=quickfix', {}), [[expand('%')], {'output': 'quickfix'}])
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
