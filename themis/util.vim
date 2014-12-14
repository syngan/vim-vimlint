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

function! s:suite.skip_modifiers_excmd()
  let F = function("vimlint#util#skip_modifiers_excmd")
  call s:assert.equals(F('put `=hoge'), 'put `=hoge')
  call s:assert.equals(F('echo "hoge"'), 'echo "hoge"')
  call s:assert.equals(F('silent echo "hoge"'), 'echo "hoge"')
  call s:assert.equals(F('silent! echo "hoge"'), 'echo "hoge"')
  call s:assert.equals(F('sil echo "hoge"'), 'echo "hoge"')
  call s:assert.equals(F('sil! echo "hoge"'), 'echo "hoge"')
  call s:assert.equals(F('unsilent echo "hoge"'), 'echo "hoge"')
  call s:assert.equals(F('uns echo "hoge"'), 'echo "hoge"')
  call s:assert.equals(F('sil uns echo "hoge"'), 'echo "hoge"')
  call s:assert.equals(F('verb echo "hoge"'), 'echo "hoge"')
  call s:assert.equals(F('silent! put =x'), 'put =x')
endfunction

function! s:suite.req_parse_excmd()
  let F = function("vimlint#util#req_parse_excmd")
  for pre in ['cexpr', 'lexpr', 'cex', 'lex', 'cex!', 'lexpr!',
        \ 'cgetexpr', 'lgetexpr', 'cgete', 'lgete',
        \ 'caddexpr', 'laddexpr', 'cadde', 'ladde',
        \]
    call s:assert.equals(F(pre . 'system(''grep -n xyz *'')'), 'system(''grep -n xyz *'')')
    call s:assert.equals(F(pre . 'system(''grep -n xyz *'')'), 'system(''grep -n xyz *'')')
    call s:assert.equals(F(pre . 'system(''grep -n xyz *'')'), 'system(''grep -n xyz *'')')
    call s:assert.equals(F(pre . 'geline(1, ''$'')'), 'geline(1, ''$'')')
    call s:assert.equals(F(pre . 'expand("%") . ":" . line(".")'), 'expand("%") . ":" . line(".")')
  endfor
  call s:assert.equals(F('put =''path'' . \",test\"'), '''path'' . ",test"')
  call s:assert.equals(F('put =x'), 'x')
  call s:assert.equals(F('e `=tempname()`'), 'tempname()')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
