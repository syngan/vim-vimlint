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

function! s:funcs.getregtype(vl, fname, node) " {{{
  let rlist = a:node.rlist
  for i in range(len(rlist))
    if vimlint#util#notstr_type(rlist[i])
      call s:EVL108(a:vl, a:node, i+1, a:fname, 'a regname')
    endif
  endfor
endfunction " }}}

function! s:funcs.keys(vl, fname, node) " {{{
  let rlist = a:node.rlist
  for i in range(1)
    if vimlint#util#notdict_type(rlist[i])
      call s:EVL108(a:vl, a:node, i+1, a:fname, 'a dictionary')
    endif
  endfor
endfunction " }}}

function! s:funcs.line(vl, fname, node) " {{{
  let rlist = a:node.rlist
  let flag = rlist[0]
  if vimlint#util#isstr_type(flag)
    let str = vimlint#util#str_value(flag)
    if str !~# '^[.$v]$' && str !~# '^''[a-zA-Z0-9<>''`"^.(){}[\]]$' && str !~# '^w[0$]$'
      call s:EVL108(a:vl, a:node, 2, a:fname, 'the accepted positions')
    endif
  endif
endfunction " }}}

let s:funcs.max = s:funcs.List1
let s:funcs.min = s:funcs.List1

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
      elseif str =~# 'e' && str =~# 'n'
        call s:EVL108(a:vl, a:node, 2, a:fname, 'either "e" or "n"')
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
    endif
  endfor

  let flag = rlist[3]
  if vimlint#util#isstr_type(flag)
    let str = vimlint#util#str_value(flag)
    if str != "" && str != "g"
      call s:EVL108(a:vl, a:node, 4, a:fname, 'either "g" or ""')
    endif
  endif
endfunction " }}}

function! s:funcs.writefile(vl, fname, node) " {{{
  let rlist = a:node.rlist
  if vimlint#util#notlist_type(rlist[0])
      call s:EVL108(a:vl, a:node, 1, a:fname, 'a list')
  endif
  if vimlint#util#notstr_type(rlist[1])
      call s:EVL108(a:vl, a:node, 2, a:fname, 'a string')
  endif
  if len(rlist) >= 3
    if vimlint#util#isstr_type(rlist[2])
      let str = vimlint#util#str_value(rlist[2])
      if str =~# '[^ba]'
        call s:EVL108(a:vl, a:node, 3, a:fname, '"ba"')
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
