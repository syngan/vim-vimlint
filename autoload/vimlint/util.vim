scriptencoding utf-8

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
  return a:node.type == 83 ||
        \ vimlint#util#isid_type(a:node) && a:node.value =~# '^[gbwtslva]:$'
endfunction " }}}

function! vimlint#util#isid_type(node) " {{{
  return a:node.type == 86
endfunction " }}}

function! vimlint#util#notstr_type(node) " {{{
  " 変数などは判定できないので isstr_type() ではエラー判定できないため.
  return vimlint#util#islist_type(a:node) ||
  \  vimlint#util#isdict_type(a:node)
endfunction " }}}

function! vimlint#util#notdict_type(node) " {{{
  return vimlint#util#islist_type(a:node) ||
  \  vimlint#util#isstr_type(a:node) ||
  \  vimlint#util#isnum_type(a:node)
endfunction " }}}

function! vimlint#util#notlist_type(node) " {{{
  return vimlint#util#isdict_type(a:node) ||
  \  vimlint#util#isstr_type(a:node) ||
  \  vimlint#util#isnum_type(a:node)
endfunction " }}}

function! vimlint#util#str_value(node) " {{{
  " node が str と一致するか.
  " isstr_type() で判定済みと仮定
  return eval(a:node.value)
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

function! vimlint#util#output_echo(filename, pos, ev, eid, mes, ...) " {{{
  echo a:filename . ":" . a:pos.lnum . ":" . a:pos.col . ":" . a:ev . ": " . a:eid . ': ' . a:mes
endfunction " }}}

function! vimlint#util#output_vimconsole(filename, pos, ev, eid, mes, ...) " {{{
  call vimconsole#log(a:filename . ":" . a:pos.lnum . ":" . a:pos.col . ":" . a:ev . ": " . a:eid . ': ' . a:mes)
endfunction "}}}

function! vimlint#util#output_file(filename, pos, ev, eid, mes, obj) " {{{
  let a:obj.error += [a:filename . ":" . a:pos.lnum . ":" . a:pos.col . ":" . a:ev . ': ' . a:eid . ': ' . a:mes]
endfunction " }}}

" @vimlint(EVL103, 1, a:param)
function! vimlint#util#hook_after_file(filename, param, c) " {{{
  let c = a:c
  if filewritable(c.param.output.filename)
    let lines = extend(readfile(c.param.output.filename), c.error)
  else
    let lines = c.error
  endif
  let lines = extend([a:filename . ' start'], lines)
  call writefile(lines, c.param.output.filename)
endfunction " }}}
" @vimlint(EVL103, 0, a:param)

function! vimlint#util#output_list(filename, pos, ev, eid, mes, obj) " {{{
  let a:obj.error += [[a:filename, a:pos.lnum, a:pos.col, a:ev, a:eid, a:mes]]
endfunction " }}}

function! vimlint#util#output_quickfix(filename, pos, ev, eid, mes, ...) " {{{
  let d = {}
  let d.filename = a:filename
  let d.lnum = a:pos.lnum
  let d.col = a:pos.col
  let d.vcol = 0
  let d.nr = a:eid
  let d.text = a:eid . ":" . a:mes
  let d.type = a:ev[0]
		    " bufnr	buffer number; must be the number of a valid buffer
		    " pattern	search pattern used to locate the error
  call setqflist([d], 'a')
endfunction " }}}

function! vimlint#util#isvarname(s) "{{{
  return a:s =~# '^[vgslabwt]:$\|^\([vgslabwt]:\)\?[A-Za-z_][0-9A-Za-z_#]*$'
endfunction "}}}

function! vimlint#util#is_mark(s) " {{{
  return a:s =~# '^''[a-zA-Z0-9<>''`"^.(){}[\]]$'
endfunction " }}}

function! vimlint#util#stol(str) " {{{
  let list = []
  let str = a:str
  while str !~# '^\s*$'
    let str = matchstr(str, '^\s*\zs.*$')
    if str[0] == "'"
      let arg = matchstr(str, '\v''\zs[^'']*\ze''')
      let str = str[strlen(arg) + 2 :]
    elseif str[0] == '"'
      let arg = matchstr(str, '\v"\zs[^"]*\ze"')
      let str = str[strlen(arg) + 2 :]
    else
      let arg = matchstr(str, '\S\+')
      let str = str[strlen(arg) + 0 :]
    endif
    call add(list, arg)
  endwhile

  return list
endfunction " }}}

function! vimlint#util#parse_cmdline(str, conf) " {{{
  let s = vimlint#util#stol(a:str)
  let s = filter(s, 'v:val != ""')
  let brk = -1
  for i in range(len(s))
    if s[i] == '--'
      let brk = i + 1
      break
    endif
    let l = matchlist(s[i], '^-\([a-z]\+\)=\(.\+\)$')
    if l == []
      let brk = i
      break
    endif
    let a:conf[l[1]] = l[2]
  endfor
  if brk == -1
    let s = [expand('%')]
  else
    let s = s[brk : ]
  endif
  return [s, a:conf]
endfunction " }}}

function! vimlint#util#complete(A, ...) " {{{
  " コマンドオプション
  if len(a:A) > 0 && a:A[0] == '-'
    let ret = ['-output=', '-quiet=', '-recursive=', '-EVL']
    let ret = filter(ret, printf('v:val =~# ''^%s''', a:A))
    return ret
  endif

  " ファイル
  if len(a:A) == 0
    let dir = "."
  else
    let dir = a:A
  endif
  if isdirectory(dir) && dir[len(dir)-1] != '/'
    let dir .= '/'
  endif
  let list = split(glob(dir . '*'), "\n")
  let list = filter(list, 'isdirectory(v:val) || v:val =~# ''.vim$''')
  let list = map(list, 'isdirectory(v:val) ? v:val . "/" : v:val')
  return list
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0 fdm=marker:
