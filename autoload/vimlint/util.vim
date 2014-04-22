scriptencoding utf-8
" ユーティリティ

let s:save_cpo = &cpo
set cpo&vim

function! vimlint#util#isnum_type(node) " {{{
  return a:node.type == 80
endfunction " }}}

function! vimlint#util#isstr_type(node) " {{{
  return a:node.type == 81
endfunction " }}}

function! vimlint#util#islist_type(node) " {{{
  return a:node.type == 82
endfunction " }}}

function! vimlint#util#isdict_type(node) " {{{
  return a:node.type == 83
endfunction " }}}

function! vimlint#util#notstr_type(node) " {{{
  return vimlint#util#islist_type(a:node) ||
  \  vimlint#util#isdict_type(a:node)
endfunction " }}}

function! vimlint#util#notdict_type(node) " {{{
  return vimlint#util#islist_type(a:node) ||
  \  vimlint#util#isstr_type(a:node) ||
  \  vimlint#util#isnum_type(a:node)
endfunction " }}}

function! vimlint#util#isstr_value(node, str) " {{{
  return a:node.value ==# '"' . a:str . '"' ||
        \ a:node.value ==# "'" . a:str . "'"
endfunction " }}}


function! s:valid_pos(pos) "{{{
  return has_key(a:pos, 'lnum')
endfunction "}}}

function! s:get_pos(node, depth) " {{{
  if a:depth <= 0
    return {}
  endif

  if type(a:node) != type({}) 
    return {}
  endif

  if has_key(a:node, 'pos')
    let pos = a:node.pos
    if s:valid_pos(pos)
      return pos
    endif
  endif

  for k in ['left', 'right']
    if has_key(a:node, k)
      echo a:node[k]
      let p = s:get_pos(a:node[k], a:depth - 1)
      if s:valid_pos(p)
        return p
      endif
    endif
  endfor

  return {}
endfunction " }}}

function! vimlint#util#get_pos(node) " {{{
  let p = s:get_pos(a:node, 10)
  if s:valid_pos(p)
    return p
  else
    return {'lnum' : '', 'col' : '', 'i' : 'EVL999'}
  endif
endfunction " }}}

" @vimlint(EVL103, 1, a:obj)
function! vimlint#util#output_echo(filename, pos, ev, eid, mes, obj) " {{{
  echo a:filename . ":" . a:pos.lnum . ":" . a:pos.col . ":" . a:ev . ": " . a:eid . ': ' . a:mes
endfunction " }}}

function! vimlint#util#output_vimconsole(filename, pos, ev, eid, mes, obj) " {{{
  call vimconsole#log(a:filename . ":" . a:pos.lnum . ":" . a:pos.col . ":" . a:ev . ": " . a:eid . ': ' . a:mes)
endfunction "}}}
" @vimlint(EVL103, 0, a:obj)

function! vimlint#util#output_file(filename, pos, ev, eid, mes, obj) " {{{
  let a:obj.error += [a:filename . ":" . a:pos.lnum . ":" . a:pos.col . ":" . a:ev . ': ' . a:eid . ': ' . a:mes]
endfunction " }}}

function! vimlint#util#output_list(filename, pos, ev, eid, mes, obj) " {{{
  let a:obj.error += [[a:filename, a:pos.lnum, a:pos.col, a:ev, a:eid, a:mes]]
endfunction " }}}

function! vimlint#util#isvarname(s)"{{{
  return a:s =~# '^[vgslabwt]:$\|^\([vgslabwt]:\)\?[A-Za-z_][0-9A-Za-z_#]*$'
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0 foldmethod=marker:
