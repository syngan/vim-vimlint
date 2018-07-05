scriptencoding utf-8

let s:save_cpo = &cpo

let s:funcs = {}

function! s:EVL108(vl, node, n, fname, mes) " {{{
  if a:n == 1
    let nth = "1st"
  elseif a:n == 2
    let nth = "2nd"
  elseif a:n == 3
    let nth = "3rd"
  else
    let nth = a:n . "th"
  endif

  call a:vl.error_mes(a:node, 'EVL108', nth . " argument of " . a:fname . " should be " . a:mes, 1)
endfunction " }}}

function! s:funcs.List1(vl, fname, node) " {{{
  let rlist = a:node.rlist
  if vimlint#util#notlist_type(rlist[0])
    call s:EVL108(a:vl, a:node, 1, a:fname, 'a list')
  endif
endfunction " }}}

function! s:eval_test(vl, fname, node, i) " {{{
  let flag = a:node.rlist[a:i]
  if vimlint#util#isstr_type(flag)
    let str = vimlint#util#str_value(flag)
    call a:vl.parse_string(str, a:node, a:fname, 1)
  elseif vimlint#util#notstr_type(a:node.rlist[a:i])
    call s:EVL108(a:vl, a:node, a:i+1, a:fname, 'a string')
  endif
endfunction " }}}

" help によるとこのチェックが必要だけど,
" ソースからして, line() と同じものを受け入れる様子 (#63)
" function! s:funcs.col(vl, fname, node) " {{{
"   let rlist = a:node.rlist
"   let flag = rlist[0]
"   if vimlint#util#isstr_type(flag)
"     let str = vimlint#util#str_value(flag)
"     if str !~# '^[.$]$' && !vimlint#util#is_mark(str)
"       call s:EVL108(a:vl, a:node, 1, a:fname, 'the accepted positions')
"     endif
"   endif
" endfunction " }}}

function! s:funcs.delete(vl, fname, node) " {{{
  let rlist = a:node.rlist
  for i in range(len(rlist))
    if vimlint#util#notstr_type(rlist[i])
        call s:EVL108(a:vl, a:node, i+1, a:fname, 'a string')
        return
    endif
  endfor
  if len(rlist) >= 2
    if vimlint#util#isstr_type(rlist[1])
      let str = vimlint#util#str_value(rlist[1])
      if str !=# 'd' && str !=# 'rf'
        call s:EVL108(a:vl, a:node, 2, a:fname, '"d" or "rf"')
        return
      endif
    endif
  endif
endfunction " }}}

function! s:funcs.eval(vl, fname, node) " {{{
  call s:eval_test(a:vl, a:fname, a:node, 0)
endfunction " }}}

function! s:filename_modifiers(vl, fname, node, str, idx) abort " {{{
  let ert = {'e': 0, 'r': 0, 't': 0}
  let str = a:str
  while str =~# '^:'
    if str =~# '^:[p8~.S]'
      let str = str[2:]
    elseif str =~# '^:[hert]'
      " ng:
      "   ert -> h
      "   re  -> t
      "   re  -> r
      "   re   -> e
      if str[1] ==# 'h'
        if ert['e'] || ert['r'] || ert['t']
          break
        endif
      else
        if ert['e'] || ert['r']
          break
        endif
      endif
      let ert[str[1]] = 1
      let str = str[2:]
    elseif str =~# '^:g\=s'
      let end = matchend(str, '^:g\=s\(.\).\+\1.*\1')
      if end < 0
        break
      endif
      let str = str[end :]
    else
      break
    endif
  endwhile

  if str !=# ''
    call s:EVL108(a:vl, a:node, a:idx, a:fname, 'a valid file-modifier: ' . str)
  endif
endfunction " }}}

function! s:funcs.expand(vl, fname, node) " {{{
  let rlist = a:node.rlist
  if vimlint#util#notstr_type(rlist[0])
    call s:EVL108(a:vl, a:node, 1, a:fname, 'a string')
    return
  endif
  if vimlint#util#isstr_type(rlist[0])
    let str = vimlint#util#str_value(rlist[0])
    if str =~# '^[A-Za-z0-9_]\+'
      " 多分 expand 使う必要がない.
      call s:EVL108(a:vl, a:node, 1, a:fname, 'a wildcard')
      return
    endif
    if str =~# '^<'
      if str !~# '^<\(cword\|cWORD\|client\|cfile\|afile\|abuf\|amatch\|sfile\|slnum\)>'
        call s:EVL108(a:vl, a:node, 1, a:fname, 'a valid name')
        return
      endif
      let str = substitute(str, '^[^>]\+>', '', '')
    elseif str =~# '^%'
      let str = str[1: ]
    elseif str =~# '^#'
      let str = substitute(str, '^#\(#\=\|<\=\d\+\)', '', '')
    else
      let str = ''
    endif

    call s:filename_modifiers(a:vl, a:fname, a:node, str, 1)
  endif
endfunction " }}}

function! s:funcs.extend(vl, fname, node) " {{{
  let rlist = a:node.rlist
  if vimlint#util#islist_type(rlist[0])
    if vimlint#util#notlist_type(rlist[1])
      call s:EVL108(a:vl, a:node, 2, a:fname, 'a list')
      return
    endif
  elseif !vimlint#util#isdict_type(rlist[0])
    return
  endif

  if vimlint#util#notdict_type(rlist[1])
    call s:EVL108(a:vl, a:node, 2, a:fname, 'a dictionary')
    return
  endif

  if len(rlist) > 2
    if vimlint#util#isstr_type(rlist[2])
      let str = vimlint#util#str_value(rlist[2])
      if str !=# 'keep' && str !=# 'force' && str !=# 'error'
        call s:EVL108(a:vl, a:node, 3, a:fname, 'either "keep", "force" or "error"')
        return
      endif
    endif
  endif

  if vimlint#util#isid_type(rlist[0]) && rlist[0].value =~# '^[ls]:$'
    " l: とか s: が展開された場合は,
    " 未定義(EVL101)とは言えなくなる.
    " @TODO rlist[1] が具体的な場合はどうするか.
    let a:vl.env.extend = 1
  endif
endfunction " }}}

function! s:funcs.filter(vl, fname, node) " {{{
  call s:eval_test(a:vl, a:fname, a:node, 1)
endfunction " }}}

function! s:funcs.fnamemodify(vl, fname, node) " {{{
  let rlist = a:node.rlist
  if vimlint#util#notstr_type(rlist[1])
    call s:EVL108(a:vl, a:node, 2, a:fname, 'a string')
    return
  endif
  if vimlint#util#isstr_type(rlist[1])
    let str = vimlint#util#str_value(rlist[1])
    call s:filename_modifiers(a:vl, a:fname, a:node, str, 1)
  endif
endfunction " }}}

" @vimlint(EVL103, 1, a:fname)
function! s:funcs.get(vl, fname, node) " {{{
  let rlist = a:node.rlist
  " l: は参照したことにしてください (issue60)
  if vimlint#util#isid_type(rlist[0]) && rlist[0].value ==# 'l:'
    if vimlint#util#isstr_type(rlist[1])
      let str = vimlint#util#str_value(rlist[1])
      call vimlint#exists_var(a:vl, a:vl.env, rlist[1], 0, str)
    endif
  endif
endfunction " }}}
" @vimlint(EVL103, 0, a:fname)

function! s:funcs.getregtype(vl, fname, node) " {{{
  let rlist = a:node.rlist
  for i in range(len(rlist))
    if vimlint#util#notstr_type(rlist[i])
      call s:EVL108(a:vl, a:node, i+1, a:fname, 'a regname')
    endif
  endfor
endfunction " }}}

let s:feature_list = vimlint#feature#list()

function! s:funcs.has(vl, fname, node) " {{{
  let rlist = a:node.rlist
  if vimlint#util#notstr_type(rlist[0])
    call s:EVL108(a:vl, a:node, 1, a:fname, 'a string')
  endif
  if vimlint#util#isstr_type(rlist[0])
    let str = vimlint#util#str_value(rlist[0])
    if str !~# 'patch[0-9]\+' &&
          \ str !~# 'patch-[0-9]\+\.[0-9]\+\.[0-9]\+' &&
          \ str !~# 'nvim-[0-9]\+\.[0-9]\+\.[0-9]\+' &&
          \ !has_key(s:feature_list, tolower(str))
      call s:EVL108(a:vl, a:node, 1, a:fname, 'a feature ('.str.'). See :h feature-list.')
    endif
  endif
endfunction " }}}

function! s:funcs.keys(vl, fname, node) " {{{
  let rlist = a:node.rlist
  for i in range(1)
    if vimlint#util#notdict_type(rlist[i])
      call s:EVL108(a:vl, a:node, i+1, a:fname, 'a dictionary')
    endif
  endfor
endfunction " }}}

function! s:funcs.map(vl, fname, node) " {{{
  call s:eval_test(a:vl, a:fname, a:node, 1)
endfunction " }}}

function! s:funcs.line(vl, fname, node) " {{{
  let rlist = a:node.rlist
  let flag = rlist[0]
  if vimlint#util#isstr_type(flag)
    let str = vimlint#util#str_value(flag)
    if str !~# '^[.$v]$' && !vimlint#util#is_mark(str) && str !~# '^w[0$]$'
      call s:EVL108(a:vl, a:node, 1, a:fname, 'the accepted positions')
    endif
  endif
endfunction " }}}
let s:funcs.getpos = s:funcs.line
let s:funcs.col = s:funcs.line
let s:funcs.virtcol = s:funcs.col

let s:funcs.max = s:funcs.List1
let s:funcs.min = s:funcs.List1

function! s:funcs.printf(vl, fname, node) " {{{
  if !vimlint#util#isstr_type(a:node.rlist[0])
    return
  endif
  let str = vimlint#util#str_value(a:node.rlist[0])
  let len = strlen(str)
  let idx = 0
  let num = 0

  while idx < len
    let pct = match(str, '%', idx)
    if pct < 0
      break
    endif

    let idx = pct + 1

    " flags
    while idx < len && str[idx] =~# '^[-+ #0]$'
      let idx += 1
    endwhile

    " field-width
    if idx < len && str[idx] == '*'
      let idx += 1
      let num += 1
    else
      while idx < len && str[idx] =~# '^[0-9]'
        let idx += 1
      endwhile
    endif

    " .precision
    if idx < len && str[idx] == '.'
      let idx += 1
      if idx == len
        call s:EVL108(a:vl, a:node, 1, a:fname, 'the valid format (invalid precision' . pct . ')')
        return
      endif
      if str[idx] == '*'
        let idx += 1
        let num += 1
      else
        while idx < len && str[idx] =~# '^[0-9]'
          let idx += 1
        endwhile
      endif
    endif

    " type
    if idx == len
      call s:EVL108(a:vl, a:node, 1, a:fname, 'the valid format (missing type, pos=' . pct . ')')
    elseif str[idx] == '%'
      let idx += 1
    elseif str[idx] =~# '^[doxXcsSfeEgG%]'
      " %O, %D are not documented
      " iDUOF see message.c vim_snprintf()
      let idx += 1
      let num += 1
    else
      call s:EVL108(a:vl, a:node, 1, a:fname, 'the valid format (unknown type, pos=' . pct . ')')
      return
    endif
  endwhile

  if num != len(a:node.rlist) - 1
    if num > len(a:node.rlist) - 1
      call a:vl.error_mes(a:node, 'E119', 'Not enough arguments for function: ' . a:node.left.value, 1)
    else
      call a:vl.error_mes(a:node, 'E118', 'Too many arguments for function: ' . a:node.left.value, 1)
    endif
  endif
endfunction " }}}

function! s:funcs.search(vl, fname, node) " {{{
" search({pattern} [, {flags} [, {stopline} [, {timeout}]]])	*search()*
" flags は "" or "g"
  let rlist = a:node.rlist

  for i in range(min([2, len(rlist)]))
    if vimlint#util#notstr_type(rlist[i])
      call s:EVL108(a:vl, a:node, i+1, a:fname, 'a string')
    endif
  endfor

  if len(rlist) >= 2
    let flag = rlist[1]
    if vimlint#util#isstr_type(flag)
      let str = vimlint#util#str_value(flag)
      if str =~# '[^bcenpswW]'
        call s:EVL108(a:vl, a:node, 2, a:fname, '"bcenpswW"')
      elseif str =~# 'w' && str =~# 'W'
        call s:EVL108(a:vl, a:node, 2, a:fname, 'either "w" or "W"')
      elseif str =~# 's' && str =~# 'n'
        call s:EVL108(a:vl, a:node, 2, a:fname, 'either "s" or "n"')
      " elseif str =~# 'e' && str =~# 'n'
      "   call s:EVL108(a:vl, a:node, 2, a:fname, 'either "e" or "n"')
      elseif str =~# '\(.\).*\1'
        call s:EVL108(a:vl, a:node, 2, a:fname, 'once')
      endif
    endif
  endif
endfunction " }}}

function! s:funcs.searchpair(vl, fname, node) " {{{
" searchpair({start}, {middle}, {end} [, {flags} [, {skip} [, {stopline} [, {timeout}]]]])
" flags は "" or "g"
  let rlist = a:node.rlist

  for i in range(min([4, len(rlist)]))
    if vimlint#util#notstr_type(rlist[i])
      call s:EVL108(a:vl, a:node, i+1, a:fname, 'a string')
    endif
  endfor

  if len(rlist) >= 4
    let flag = rlist[3]
    if vimlint#util#isstr_type(flag)
      let str = vimlint#util#str_value(flag)
      if str =~# '[^bcnswWrm]'
        call s:EVL108(a:vl, a:node, 2, a:fname, '"bcnswWrm"')
      elseif str =~# 'w' && str =~# 'W'
        call s:EVL108(a:vl, a:node, 2, a:fname, 'either "w" or "W"')
      elseif str =~# 's' && str =~# 'n'
        call s:EVL108(a:vl, a:node, 2, a:fname, 'either "s" or "n"')
      elseif str =~# '\(.\).*\1'
        call s:EVL108(a:vl, a:node, 2, a:fname, 'once')
      endif
    endif
  endif
endfunction " }}}

let s:funcs.searchpairpos = s:funcs.searchpair

let s:funcs.searchpos = s:funcs.search

function! s:funcs.setpos(vl, fname, node) " {{{
  let rlist = a:node.rlist
  let flag = rlist[1]
  if vimlint#util#isstr_type(flag)
    let str = vimlint#util#str_value(flag)
    if str !=# '.' && vimlint#util#is_mark(str)
      call s:EVL108(a:vl, a:node, 2, a:fname, '"." or "''x"(mark x)')
    endif
  endif

endfunction " }}}

function! s:funcs.setqflist(vl, fname, node) " {{{
  let rlist = a:node.rlist
  if len(rlist) >= 2
    let flag = rlist[1]
    if vimlint#util#isstr_type(flag)
      let str = vimlint#util#str_value(flag)
      if str !~# '^[ar ]$'
        call s:EVL108(a:vl, a:node, 2, a:fname, 'either "a", "r" or " "')
      endif
    endif
  endif
endfunction " }}}

function! s:funcs.substitute(vl, fname, node) " {{{
" substitute({expr}, {pat}, {sub}, {flags})		*substitute()*
" flags は "" or "g"
  let rlist = a:node.rlist

  for i in range(4)
    if vimlint#util#notstr_type(rlist[i])
      call s:EVL108(a:vl, a:node, i+1, a:fname, 'a string')
      return
    endif
  endfor

  if type(rlist[2]) == type({})
  \ && has_key(rlist[2], 'value') && rlist[2].value =~# '^[''"]\\='
    let str = vimlint#util#str_value(rlist[2])
    call a:vl.parse_string(str[2:], a:node, a:fname, 1)
  endif

  let flag = rlist[3]
  if vimlint#util#isstr_type(flag)
    let str = vimlint#util#str_value(flag)
    if str != "" && str != "g"
      call s:EVL108(a:vl, a:node, 4, a:fname, 'either "g" or ""')
      return
    endif
  endif
endfunction " }}}

function! s:funcs.writefile(vl, fname, node) " {{{
  let rlist = a:node.rlist
  if vimlint#util#notlist_type(rlist[0])
      call s:EVL108(a:vl, a:node, 1, a:fname, 'a list')
      return
  endif
  if vimlint#util#notstr_type(rlist[1])
      call s:EVL108(a:vl, a:node, 2, a:fname, 'a string')
      return
  endif
  if len(rlist) >= 3
    if vimlint#util#isstr_type(rlist[2])
      let str = vimlint#util#str_value(rlist[2])
      if str =~# '[^ba]'
        call s:EVL108(a:vl, a:node, 3, a:fname, '"ba"')
        return
      endif
    endif
  endif
endfunction " }}}

function! vimlint#builtin_arg#check(vl, fname, node) " {{{
  if has_key(s:funcs, a:fname)
    return s:funcs[a:fname](a:vl, a:fname, a:node)
  endif
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0 fdm=marker:
