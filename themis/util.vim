scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:suite = themis#suite('util')
let s:assert = themis#helper('assert')

let s:debug = 1

function! s:suite.before()
endfunction

function! s:suite.before_each()
endfunction

function! s:suite.after_each()
  quit!
endfunction

function! s:suite.stol()
  call s:assert.equals(vimlint#util#stol(''), [])
  call s:assert.equals(vimlint#util#stol('a'), ['a'])
  call s:assert.equals(vimlint#util#stol('a b c'), ['a', 'b', 'c'])
  call s:assert.equals(vimlint#util#stol('"a b" c'), ['a b', 'c'])
  call s:assert.equals(vimlint#util#stol("'a b' c"), ['a b', 'c'])
  call s:assert.equals(vimlint#util#stol('"a '' b" c'), ['a '' b', 'c'])
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
