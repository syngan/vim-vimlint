scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" 最低限やりたいこと {{{
" - let つけずに変数代入
" - call つけずに関数呼び出し
" - built-in 関数関連の引数チェック
" @TODO `=` は let 以外で使う場面があるか?
"
" Variable i used before definition
" An rvalue is used that may not be initialized to a value on some execution
" path. (Use -usedef to inhibit warning)
"
" }}}

" global variables {{{
let g:vimlint#debug = get(g:, 'vimlint#debug', 0)
" }}}

let s:vlp = vimlparser#import()

let s:VimlLint = {}

" statistics
" let g:VimLint__stat = {}
" function! s:__called(f)
"   if !has_key(g:VimLint__stat, a:f)
"     let g:VimLint__stat[a:f] = 1
"   else
"     let g:VimLint__stat[a:f] += 1
"   endif
" endfunction


let s:default_param = {} " {{{
let s:default_param.parse_py = 0
let s:default_param.recursive = 1
let s:default_param.quiet = 0
let s:default_param.type = 'file'
let s:default_param.func_abort = 0

let s:default_param_output = {
\   'append' : 0,
\   'filename' : ''}
" }}}

" 5 必ずエラー
" 3 警告に変更可能
" 1 無視可能
" 0 元に戻す.
let s:DEF_ERR = 5
let s:DEF_WRN = 3
let s:DEF_NON = 1
let s:default_errlevel = {}
let s:default_errlevel.EVL101 = s:DEF_NON
let s:default_errlevel.EVL102 = s:DEF_NON
let s:default_errlevel.EVL103 = s:DEF_NON
let s:default_errlevel.EVL104 = s:DEF_NON
let s:default_errlevel.EVL105 = s:DEF_WRN
let s:default_errlevel.EVL107 = s:DEF_NON
let s:default_errlevel.EVL108 = s:DEF_NON
let s:default_errlevel.EVL109 = s:DEF_NON
let s:default_errlevel.EVL110 = s:DEF_NON
let s:default_errlevel.EVL111 = s:DEF_NON
let s:default_errlevel.EVL201 = s:DEF_NON
let s:default_errlevel.EVL202 = s:DEF_WRN
let s:default_errlevel.EVL203 = s:DEF_WRN
let s:default_errlevel.EVL204 = s:DEF_NON
let s:default_errlevel.EVL205 = s:DEF_WRN
let s:default_errlevel.EVL206 = s:DEF_NON
let s:default_errlevel.EVL207 = s:DEF_NON
let s:default_errlevel.EVL301 = s:DEF_NON
let s:default_errlevel.EVL302 = s:DEF_NON
let s:default_errlevel.EVL901 = s:DEF_WRN
let s:default_errlevel.EVL902 = s:DEF_WRN
let s:def_var_name = ':'

function! s:bak_param(param, key, var) abort " {{{
  if !has_key(a:param.bak, a:key)
    " 一度もセットされていない
    return
  endif
  let dict = a:param.bak[a:key]
  if has_key(dict, a:var)
    let elv = dict[a:var]
  else
    let elv = dict[s:def_var_name]
  endif

  call s:set_param(a:param, a:key, elv, a:var)

endfunction " }}}

function! s:set_param(param, key, errlv, var) abort " {{{
" echo "set_param[" . a:key . "," . a:var . "]=" . a:errlv
  let key = a:key
  let param = a:param
  if has_key(param, key)
    if type(param[key]) != type({})
      unlet param[key]
      let param[key] = {s:def_var_name : s:DEF_ERR}
    endif
  else
    let param[key] = {s:def_var_name : s:DEF_ERR}
  endif

  if !has_key(s:default_errlevel, key)
    " unknown error code
    return
  endif
  if a:errlv < s:default_errlevel[key]
    let elv = s:default_errlevel[key]
  elseif a:errlv > s:DEF_ERR
    let elv = s:DEF_ERR
  else
    let elv = a:errlv
  endif
  let dict = param[key]
  if g:vimlint#debug > 0
    echo 'vimlint: set_param(' . key . ':' . a:var . ')=' . elv
  endif
  if has_key(dict, a:var)
    unlet dict[a:var]
  endif
  let dict[a:var] = elv
endfunction " }}}

function! s:extend_errlevel(param) abort " {{{
  let param = a:param
  for key in keys(s:default_errlevel)
"   echo "param[" . key . "]"
    if !has_key(param, key)
      call s:set_param(param, key, key[3] == '3' ? s:DEF_WRN : s:DEF_ERR, s:def_var_name)
    elseif type(param[key]) == type(0)
      call s:set_param(param, key, param[key], s:def_var_name)
    elseif type(param[key]) != type({})
      call s:set_param(param, key, s:DEF_ERR, s:def_var_name)
    else
      for k in keys(param[key])
        call s:set_param(param, key, param[key][k], k)
      endfor
      if !has_key(param[key], s:def_var_name)
        call s:set_param(param, key, s:DEF_ERR, s:def_var_name)
      endif
    endif
  endfor

  for key in keys(param)
    if key =~# '^E[1-9]\+$'
      " 設定されていても無視
      unlet param[key]
    elseif key =~# '^EVP[1-9]\+$' || key =~# '^EVP_.*$'
      " 設定されていても無視
      unlet param[key]
    elseif key =~# '^EVL[1-9]\+$' && type(param[key]) != type(0)
      " もし実際にこのエラーがあるとすると,
      " s:default_errlevel の更新漏れ.
      " とりあえず, 最高レベルのエラーで設定しておく.
      call s:set_param(param, key, s:DEF_ERR, s:def_var_name)
    endif
  endfor

  return param
endfunction " }}}

function s:VimlLint.new(param) abort " {{{
  let obj = copy(self)
  let obj.indent = ['']
  let obj.lines = []
  let obj.env = s:env({}, '')

  let obj.param = a:param
  let obj.error = []
  let obj.errnum = 0
  return obj
endfunction " }}}

function! s:tostring_varstack_n(v) abort " {{{
  let v = a:v
  let s = ''
  let s .= 'type=' . v.type[0:2]
  let s .= ',ref=' . v.v.ref
  let s .= ',sub=' . v.v.subs
  let s .= ',stt=' . v.v.stat
  if has_key(v, 'var')
    let s .= ',var=' . v.var
  elseif has_key(v, 'rt_from')
    let s .= ',rm=' . v.rt_from . '..' .  v.rt_to
  else
    let s .= ',var='
  endif
  return s
endfunction " }}}

function! s:env(outer, funcname, ...) abort " {{{
  let env = {}
  let env.outer = a:outer
  let env.function = a:funcname
  let env.var = {}
  let env.varstack = []
  let env.ret = 0       " どのルートを通っても return なら 1
  let env.loopb = 0     " どのルートを通っても break/continue なら 1
  let env.has_break = 0 " どこかで break/continue したら 1
  let env.is_dic_func = a:0 > 0 && a:1
  let env.extend = 0
  let env.no_prepend_var = {}
  if has_key(a:outer, 'global')
    let env.global = a:outer.global
  else
    let env.global = env
    let env.loop = 0
    let env.fins = 0
  endif
  return env
endfunction " }}}

function! s:VimlLint.error_mes(node, eid, mes, var) abort " {{{
  if type(a:var) == type('')
    let var = a:var
  else
    let var = s:def_var_name
  endif

  if !has_key(self.param, a:eid)
    let lv = s:DEF_ERR
  else
    let dict = self.param[a:eid]
    if type(dict) != type({})
      let lv = s:DEF_ERR
    else
      let lv = dict[s:def_var_name]
      for key in keys(dict)
        if var =~# '^' . key . '$'
          let lv = dict[key]
          break
        endif
      endfor
    endif
  endif
  if lv > s:DEF_NON
    let filename = get(self, 'filename', '...')
    let ev = ['None', 'None', 'Warning', 'Warning', 'Error', 'Error'][lv]
    let pos = vimlint#util#get_pos(a:node)
    call self.param.outfunc(filename, pos, ev, a:eid, a:mes, self)
    let self.errnum += 1
  endif
endfunction " }}}

" 変数参照 s:exists_var {{{
" @param var string
" @param node dict: return value of compile
"  return {'type' : 'id', 'val' : name, 'node' : a:node}
function! vimlint#exists_var(self, env, node, funcref, refonly) abort
  let var = (a:refonly is 0) ? a:node.value : a:refonly
  if var =~# '#'
    " cannot support
    return 1
  endif

  if var !~# '^[gbwtslva]:'
    " prefix なし
    let append_prefix = 1
    if a:env.global == a:env
      " global
      " check できない
      "let var = 'g:' . var
      return 1
    else
      " local
      if var ==# 'count'
        call a:self.error_mes(a:node, 'EVL106', 'local variable `' . var . '` is used without l:', var)
      endif
      let var = 'l:' . var
    endif
  elseif var =~# '^[gbwtv]:'
    " check できない
    " 型くらいは保存してみる?
    "
    " v:
    " @TODO :help v:
    " @TODO map 内などか?
    return 1
  elseif var =~# '^s:'
    " 存在していることにして先にすすむ.
    " どこで定義されるかわからない
    call s:append_var_(a:env.global, var, a:node, 0, -1)
    return 1
  else
    let append_prefix = 0
  endif

  " ローカル変数
  let env = a:env
  while has_key(env, 'var')
    let vv = env['var']
    if has_key(vv, var)
      " カウンタをアップデード
      let stat = vv[var].stat
      call s:append_var_(env, var, a:node, 0, -1)
      if stat == 0 || a:refonly isnot# 0
        return 1
      endif

      " 警告
      call a:self.error_mes(a:node, 'EVL104', 'variable may not be initialized on some execution path: `' . var . '`', var)
      return 0
    endif
    let env = env.outer
  endwhile

  " 存在しなかった
  if (!append_prefix || !a:funcref) && a:refonly is 0 && !a:self.env.extend
    " prefix なしの場合は、builtin-func
    call a:self.error_mes(a:node, 'EVL101', 'undefined variable `' . var . '`', var)
  endif
  return 0
endfunction " }}}

function! s:push_varstack(env, dict) abort " {{{

  let a:env.varstack += [a:dict]

  if !has_key(a:dict, 'type') || type(a:dict.type) != type('')
    throw 'varstack() invalid type: ' . string(a:dict)
  endif
  if !has_key(a:dict, 'v') || type(a:dict.v) != type({}) ||
  \ !has_key(a:dict.v, 'ref') || !has_key(a:dict.v, 'subs') ||
  \ !has_key(a:dict.v, 'stat')
  \ || type(a:dict.v.ref) != type(1)
  \ || type(a:dict.v.subs) != type(1)
    throw 'varstack() invalid v: ' . string(a:dict)
  endif

endfunction " }}}

function! s:append_var_(env, var, node, val, cnt) abort " {{{

"  echo "append_var: var=" . a:var . ", cnt=" . a:cnt . ", has=" . has_key(a:env.var, a:var)
  if has_key(a:env.var, a:var)
    let v = a:env.var[a:var]
    if a:cnt > 0
      let v.subs += 1
      if v.stat != 0
        " どこかのルートでは未定義だった可能性があるものを
        " ちゃんと定義した.
        "
        " if 1
        "   let a = 1
        "   ....
        " else
        "   " does not define a
        " endif
        " ...
        " let a = 2 " <= ここ
        call s:push_varstack(a:env, {
          \ 'type' : 'update',
          \ 'v' : v,
          \ 'var' : a:var,
          \ 'node' : a:node,
          \ 'val' : a:val,
          \ 'env' : a:env,
          \ 'stat' : v.stat
          \})
        let v.stat = 0

      endif
    else
      let v.ref += 1
    endif
    return v
  else
    if a:cnt > 0
      " subs/let
      let v = {'ref' : 0, 'val' : a:val, 'subs' : 1, 'node' : a:node, 'stat' : 0}
      let a:env.var[a:var] = v
      if a:env.global != a:env
        call s:push_varstack(a:env, {
          \ 'type' : 'append',
          \ 'v' : v,
          \ 'var' : a:var,
          \ 'node' : a:node,
          \ 'val' : a:val,
          \ 'env' : a:env,
          \ 'stat' : 0,
          \})
      endif
    else
      " ref
      let v = {'ref' : 1, 'subs' : 0, 'node' : a:node, 'stat' : 0}
      let a:env.var[a:var] = v
    endif

    return v
  endif
endfunction " }}}

" 変数代入s:VimlLint.append_var(env, var, val, pos) " {{{
" let でいうところの
" left node  = var
" right node = val
" pos = string
function! s:VimlLint.append_var(env, var, val, pos) abort
  if type(a:var) != type({})
    " @debug
    echo 'in append_var: invalid input: type=' . type(a:var) . ',pos=' . a:pos
    echo a:var
    throw 'stop'
  endif
  let ret = {}

  if a:var.type == s:vlp.NODE_IDENTIFIER || a:var.type == s:vlp.NODE_SLICE
    let node = a:var
    while node.type != s:vlp.NODE_IDENTIFIER
      let node = node.left
    endwhile
    let v = node.value
    if v =~# '^[0-9]*$'
      echo 'in append_var: invalid input: type=' . type(a:var) . ',pos=' . a:pos
      echo a:var
      throw 'stop'
    endif
    if a:pos ==# 'a:'
      " 関数引数
      if v !=# '...'
        let ret = s:append_var_(a:env, 'a:' . v, node, a:val, 1)
      endif
      return ret
    endif

    " 接頭子は必ずつける.
    if v =~# '^l:'
      if a:env.global == a:env
        " global area で l:
        call self.error_mes(a:var, 'EVL109', 'local variable `' . v . '` is used outside of a function', v)
      endif
    elseif v !~# '^[gbwtslva]:' && v !~# '#'
      if a:env.global == a:env
        call self.error_mes(a:var, 'EVL105', 'global variable `' . v . '` is defined without g:', v)
        let v = 'g:' . v

      else
        if v ==# 'count'
          call self.error_mes(a:var, 'EVL106', 'local variable `' . v . '` is used without l:', v)
        elseif v =~# '^[A-Z]'
          " for EVL111
          let a:env.no_prepend_var[v] = a:var
        endif
        let v = 'l:' . v
      endif
    endif
    if v =~# '^[sgbwtv]:'
      let ret = s:append_var_(a:env.global, v, node, a:val, 1)
    elseif v !~# '#'
      let ret = s:append_var_(a:env, v, node, a:val, 1)
    endif
  elseif a:var.type == s:vlp.NODE_REG
    " do nothing
    return ret
  elseif a:var.type == s:vlp.NODE_SUBSCRIPT
  elseif a:var.type == s:vlp.NODE_DOT
    " let f.f = xxxx, let f["a"] = xxxx
  elseif a:var.type == s:vlp.NODE_OPTION
    " do nothing
  elseif a:var.type == s:vlp.NODE_CURLYNAME
    " ???
  elseif a:var.type == s:vlp.NODE_ENV
    " $xxxx
  else
    " @TODO
    call self.error_mes(a:var, 'EVL901', 'unknown type `' . a:var.type . '`', 1)
  endif
  return ret
endfunction " }}}

function! s:delete_var(env, var) abort " {{{
  if a:var.type == s:vlp.NODE_IDENTIFIER
    let name = a:var.value
    if name !~# '^[gbwtslv]:' && name !~# '#'
      if a:env.global == a:env
        let name = 'g:' . name
      else
        let name = 'l:' . name
      endif
    elseif name =~# '^s:'
      return
    endif

    if has_key(a:env.var, name)
      let e = a:env
      let v = e.var[name]
      unlet a:env.var[name]
    elseif has_key(a:env.global.var, name)
      let e = a:env.global
      let v = e.var[name]
      unlet a:env.global.var[name]
    else
      return
    endif
  else
    return
  endif

  call s:push_varstack(a:env, {
    \ 'type' : 'delete',
    \ 'var' : name,
    \ 'env' : e,
    \ 'node' : a:var,
    \ 'v' : v,
    \ 'stat' : 0,
    \ 'brcon' : 0,
    \})

endfunction " }}}

function! s:reset_env_cntl(env) abort " {{{
  let a:env.ret = 0
  let a:env.loopb = 0
  let a:env.has_break = 0
endfunction " }}}

function! s:gen_pos_cntl(env, p) abort " {{{
  return [a:p, len(a:env.varstack), a:env.ret, a:env.loopb, a:env.has_break]
endfunction " }}}

" @vimlint(EVL103, 1, a:pp)
function! s:restore_varstack(env, pos, pp) abort " {{{
  " @param pp は debug 用
  call s:simpl_varstack(a:env, a:pos, len(a:env.varstack) - 1)
  let i = len(a:env.varstack)
  "call vimlint#debug#decho("restore: " . a:pp . ": " . a:pos)
  while i > a:pos
    let i = i - 1
    let v = a:env.varstack[i]
"    call vimlint#debug#decho("restore[" . a:pp . "] " . i . "/" . a:pos . "/" . (len(a:env.varstack)-1) . " : " . s:tostring_varstack_n(v))
    if v.type ==# 'delete'
      let v.env.var[v.var] = v.v
    elseif v.type ==# 'append'
      " break されたりするときの restore では
      " let されているとは限らない
      " @TODO
      if has_key(v.env.var, v.var)
        unlet v.env.var[v.var]
      endif
    elseif v.type ==# 'update'
      let v.env.var[v.var].stat = v.stat
    elseif v.type !=# 'nop'
      throw 'system error'
    endif
  endwhile
endfunction " }}}
" @vimlint(EVL103, 0, a:pp)

function! s:simpl_varstack(env, pos, pose) abort " {{{
  let d = {}
  let nop = {'type' : 'nop', 'v' : {'ref' : 0, 'subs' : 0, 'stat' : 0}}

"  call vimlint#debug#decho("simpl_varstack: " . a:pos . ".." . (len(a:env.varstack)-1))
  for i in range(a:pos, a:pose)
    let v = a:env.varstack[i]
    if v.type ==# 'nop'
      " do nothing
    elseif has_key(d, v.var)
      let j = d[v.var]
      let u = a:env.varstack[j]
      if u.type != v.type
        " let して unlet
        " unlet して let
        let a:env.varstack[i] = nop
        let a:env.varstack[j] = nop
        unlet d[v.var]
      else
        let a:env.varstack[j] = nop
        let d[v.var] = i
      endif
    else
      let d[v.var] = i
    endif
  endfor
endfunction " }}}

function! s:reconstruct_varstack_rm(self, env, pos, nop) abort " {{{
  " remake
  for p in a:pos
    for j in range(p[0], p[1] - 1)
      let v = a:env.varstack[j]
"      call vimlint#debug#decho("v[" . j . "]=" . v.type)
      if v.type ==# 'nop' && has_key(v, 'rt_from')
        " v.zz is a return value of reconstruct_varstack_rt
        " @@memo return [vardict, N, N_lp]
        let tail = len(a:env.varstack)
        call s:reconstruct_varstack_chk(a:self, a:env, v.zz, 1)
        let vs = a:env.varstack[tail :]
"        call vimlint#debug#decho("nop-:" . v.rt_from . ".." . v.rt_to . ",tail=" . tail . ",vs=" . len(vs))
        for ui in range(len(vs))
          call remove(a:env.varstack, -1)
        endfor

        let ui = v.rt_from

        " @TODO 参照情報をコピー. かなり強引.
        let vref = {}
        for ui in range(v.rt_from, v.rt_to - 1)
          let vp = a:env.varstack[ui]
          if vp.type ==# 'append'
            if has_key(vref, vp.var)
              let vref[vp.var] += vp.v.ref
            else
              let vref[vp.var] = vp.v.ref
            endif
          endif
        endfor

        let ti = 0
        let ui = v.rt_from
        for ti in range(len(vs))
          if ui + ti >= v.rt_to && a:env.varstack[ui + ti].type !=# 'nop'
            throw 'stop'
          endif
          let a:env.varstack[ui + ti] = vs[ti]
"          call vimlint#debug#decho("recon2: varstack[" . (ui+ti) . "]=vs[" . ti . "]=" . s:tostring_varstack_n(vs[ti]))
          if vs[ti].type ==# 'append' && has_key(vref, vs[ti].var)
            let vs[ti].v.ref += vref[vs[ti].var]
          endif
        endfor
        let ui = ui + ti
        while ui < v.rt_to
          let a:env.varstack[ui] = a:nop
"          echo 'recon2: varstack[' . (ui) . ']=nop'
          let ui = ui + 1
        endwhile
      endif
    endfor
    call s:simpl_varstack(a:env, p[0], p[1] - 1)
  endfor

endfunction " }}}

function! s:reconstruct_varstack_rt(self, env, pos, brk_cont, nop) abort " {{{
  " すべてのルートをチェックして,
  " 変数の代入、参照状態を構築する
  let vardict = {} " 変数情報を詰め込む
  let nop = a:nop

  let N = 0 " return しないルート数
  let N_lp = 0 " break/continue されたルート数
  let has_break = 0 " break されたか

  for p in a:pos
"    call vimlint#debug#decho("reconstruct_rt: " . string(p) . "/" . len(a:pos))
    let has_break = has_break || p[4]
    if p[2] && !p[4] " return した.
      " イベントをなかったことにする
      for j in range(p[0], p[1] - 1)
        let v = a:env.varstack[j]
        if v.type ==# 'append' && v.v.ref == 0 && a:env.global.fins == 0
          " 変数を追加したが参照していない
          " かつ,  finally 句がない場合
          call a:self.error_mes(v.node, 'EVL102', 'unused variable2 `' . v.var . '`', v.var)
        endif
        let a:env.varstack[j] = nop
      endfor
      continue
    endif
    let N += 1
"echo "p=" . string(p) . ", brk=" . a:brk_cont
    if p[3] && !a:brk_cont
      " break/continue した
      let N_lp += 1
      continue
    endif
    let vi = {}
    for j in range(p[0], p[1] - 1)
      let v = a:env.varstack[j]
"      call vimlint#debug#decho("reconstruct" . j . "/" . (p[1]-1) . ":    " . s:tostring_varstack_n(v) . ",pos=" . string(p))
      if v.type ==# 'nop'
        continue
      endif
      if has_key(vi, v.var)
        " if 文内で定義したものを削除した など
        " simplify によりありえない
        echo '============ ERR ============='
"        echo v
"        echo vi[v.var]
        throw 'err: simpl_varstack()'
      endif

      if v.type ==# 'delete'
        " if 文前に定義したものを削除した
        let vi[v.var] = [v, 0, 1, 0, 0]
      elseif v.type ==# 'append' || v.type ==# 'update'
        let vi[v.var] = [v, 1, 0, 0, 0]
      elseif v.type !=# 'nop'
        call a:self.error_mes(v.v, 'EVL901', 'unknown type `' . v.type . '`', 1)
      endif
    endfor

    " 情報をマージ
    for k in keys(vi)
"      call vimlint#debug#decho("_rt(): vi[" . k . "]=" . string(vi[k][1:]) . ",ref=" . vi[k][0].v.ref)
      if vi[k][1] != vi[k][2] " nop 以外? わかめ
        if has_key(vardict, k)
          let vardict[k][1] += vi[k][1]
          let vardict[k][2] += vi[k][2]
        else
          let vardict[k] = vi[k]
        endif
        let vardict[k][3] += vi[k][0].v.ref
        let vardict[k][4] += vi[k][0].v.subs
      endif
    endfor
  endfor

  return [vardict, N, N_lp, has_break]
endfunction " }}}

" @vimlint(EVL103, 1, a:brk_cont)
function! s:reconstruct_varstack_chk(self, env, rtret, brk_cont) abort "{{{
  " reconstruct_varstack_rt() で構築した情報をもとに,
  let vardict = a:rtret[0]
  let N = a:rtret[1]
  let N_lp = a:rtret[2]

  for k in keys(vardict)
    let z = vardict[k]
    if z[2]  + N_lp == N
      " すべてのルートで delete
      call s:delete_var(a:env, z[0].node) " -1
    else
      try
        " あるルートでは delete されなかった.
        " あるルートで append された
        " すべてのルートで append された
        let z[0].v.v = a:self.append_var(z[0].env, z[0].node, z[0].var, 'reconstruct')
        " ref 情報を追加しないと.
        if z[3] > 0
          call vimlint#exists_var(a:self, a:self.env, z[0].node, 0, 0)
        endif

      catch
        echo v:exception
        echo v:errmsg
        echo v:throwpoint
        throw 'stop'
      endtry

"echo "z=" . string(z[1]) . ",N_lp=" . N_lp . ",N=" . N
      if z[1] + N_lp != N
        " すべての route で append されていない
        " 中途半端に定義されている状態
        let var = z[0].env.var[z[0].var]
        let var.stat = 1
"echo "stat=1"
      endif
    endif
  endfor
endfunction "}}}
" @vimlint(EVL103, 0, a:brk_cont)

function! s:reconstruct_varstack(self, env, pos, is_loop, ...) abort " {{{
  " a:pos は s:gen_pos_cntl() により構築される
  " すべてのルートをみて変数定義まわりの情報を再構築する
  " test/for7.vim とか.

  let nop = {'type' : 'nop', 'v' : {'ref' : 0, 'subs' : 0, 'stat' : 0}}
"  echo "reconstruct: " . string(a:pos)

  if a:is_loop
    " varstack を modify する.
    call s:reconstruct_varstack_rm(a:self, a:env, a:pos, nop)
  endif
  let rtret = s:reconstruct_varstack_rt(a:self, a:env, a:pos, a:is_loop, nop)

  let vardict = rtret[0]
  let N = rtret[1]
  let N_lp = rtret[2]
  let a:self.env.has_break = rtret[3]

  if N == 0 && rtret[3] == 0
    " すべての route で return
    let a:self.env.ret = 1
    return
  endif

  call s:reconstruct_varstack_chk(a:self, a:env, rtret, 0)

  if N_lp == 0
    " break/continue はなかった
    return
  endif

  " for
  "   if
  "     let a = 1
  "     break
  "   ....  ここでは a は未定義
  "
  " ... ここでは a が中途半端定義
  if N == N_lp
    " すべてのルートで break/continue
    let a:self.env.loopb = 1
  endif

  if a:is_loop
    return
  endif

  " for/while の外側用に追加.
  let v = deepcopy(nop)
  let v.rt_from = a:pos[0][0]
  let v.rt_to = len(a:env.varstack)

"  call vimlint#debug#decho("construct rvrt2: range=" . v.rt_from . ".." . v.rt_to)
  let rvrt2 = s:reconstruct_varstack_rt(a:self, a:env, a:pos, 1, nop)
"  call vimlint#debug#decho("vard=" . len(vardict) . ", var2=" . len(rvrt2[0]))
  " @TODO 参照情報をコピーする.

  if len(vardict) <= len(rvrt2[0]) - 1
    " @vimlint(EVL102, 1, l:i)
    for i in range(len(vardict), len(rvrt2[0]) - 1)
      call s:push_varstack(a:env, nop)
    endfor
  endif
  let v.zz = rvrt2

  call s:push_varstack(a:env, v)
endfunction " }}}
" @vimlint(EVL102, 0, l:i)

" @vimlint(EVL103, 1, a:self)
function! s:reconstruct_varstack_st(self, env, p) abort " {{{
  " try 句の reconstrutt. どこで例外が発生するかわからない状態
  " @param p(list) reconstruct_varstack() の pos(listlist) と同じではない
  for j in range(a:p, len(a:env.varstack) - 1)
    let v = a:env.varstack[j]
    if v.type ==# 'append'
      let v.stat = 1
    endif
  endfor

endfunction " }}}
" @vimlint(EVL103, 0, a:self)

function! s:VimlLint.abbrev_if(vl, node) abort " {{{
  for node in a:node.elseif
    call a:vl.abbrev_common(node)
  endfor
  if a:node.else isnot s:vlp.NIL
    call a:vl.abbrev_common(a:node.else)
  endif
  call a:vl.abbrev_common(a:node.endif)
endfunction " }}}
function! s:VimlLint.abbrev_for(vl, node) abort " {{{
  call a:vl.abbrev_common(a:node.endfor)
endfunction " }}}
function! s:VimlLint.abbrev_while(vl, node) abort " {{{
  call a:vl.abbrev_common(a:node.endwhile)
endfunction " }}}
function! s:VimlLint.abbrev_try(vl, node) abort " {{{
  for node in a:node.catch
    call a:vl.abbrev_common(node)
  endfor
  if a:node.finally isnot s:vlp.NIL
    call a:vl.abbrev_common(a:node.finally)
  endif
  call a:vl.abbrev_common(a:node.endtry)
endfunction " }}}
function! s:VimlLint.abbrev_func(vl, node) abort " {{{
  call a:vl.abbrev_common(a:node.endfunction)
endfunction " }}}
function! s:VimlLint.abbrev_common(node) abort " {{{
  let line = self.lines[a:node.pos.lnum - 1]
  if match(line, '^' . a:node.ea.cmd.name . '\>', a:node.pos.col - 1) < 0
      call self.error_mes(a:node, 'EVL302', 'use the full command name `' . a:node.ea.cmd.name . '` instead of the abbreviation', a:node)
  endif
endfunction " }}}

function s:VimlLint.compile(node, refchk) abort " {{{
  if type(a:node) ==# type({}) && has_key(a:node, 'type')
    if a:node.type != 2 && g:vimlint#debug > 2 || g:vimlint#debug >= 5
      call vimlint#debug#echonode(a:node, a:refchk)
    endif
"  else
"    echo "node=" . type(a:node)
"    echo a:node
  endif

  " try
  "   let a:node.sg_type_str = vimlint#debug#node2str(a:node)
  " catch
  "   echo v:exception
  "   echo a:node
  "   throw "stop"
  " endtry
  if has_key(a:node, 'ea')
    if has_key(self.excmd_abbrev, a:node.type)
      call self.excmd_abbrev[a:node.type](self, a:node)
    elseif has_key(a:node.ea.cmd, 'name')
      call self.abbrev_common(a:node)
    endif
  endif


  return call(self.compile_funcs[a:node.type], [a:node, a:refchk], self)

endfunction " }}}

function s:VimlLint.compile_body(body, refchk) abort " {{{
  for node in a:body
    if self.env.ret + self.env.loopb > 0 && node.type != s:vlp.NODE_COMMENT
      call self.error_mes(node, 'EVL201', 'unreachable code: ' .
      \ (self.env.ret > 0 ? 'return/throw' : 'continue/break'), 1)
      break
    endif
    call self.compile(node, a:refchk)
  endfor
endfunction " }}}

function s:VimlLint.compile_toplevel(node, refchk) abort " {{{
  call self.compile_body(a:node.body, a:refchk)
  return self.lines
endfunction " }}}

function s:VimlLint.compile_comment(node, ...) abort " {{{
  " コメント部に @vimlint(EVLxxx, number [, var]) な形式があれば
  " それを元にエラーレベルを修正する
  " 0 は元に戻すを意味する.
  " 1 は, none. (:h vimlint-variables)
  let s = a:node.str
  let m = '^\s*@vimlint\s*(\s*\(EVL\d\+\)\s*,\s*\(\d\+\)\(\s*,\s*\(.\+\)\)\=\s*)\s*'
  let l = matchlist(s, m)
  if len(l) == 0
    return
  endif
  " if !vimlint#util#isvarname(l[4]) && l[4] !=# s:def_var_name && l[4] != ''
  "   return
  " endif

  if !has_key(self.param, l[1])
    if g:vimlint#debug > 1
      echo 'vimlint: unknown error code: ' . l[1]
    endif
    return
"    let self.param[l[1]] = s:DEF_NON
  endif

  if l[3] ==# ''
    let v = s:def_var_name
  else
    let v = l[4]
  endif
  if l[2] ==# '0'
    call s:bak_param(self.param, l[1], v)
  else
    call s:set_param(self.param, l[1], str2nr(l[2]), v)
  endif
endfunction " }}}

" @vimlint(EVL103, 1, a:refchk)
function s:VimlLint.compile_excmd(node, refchk) abort " {{{
" @TODO
" e.g. set cpo&vim
" e.g. a = 3   (let 漏れ)
  " lcd `=cwd`
  " edit/new `=file`
  " line put = expr
  if has_key(a:node, 'ea') && has_key(a:node.ea, 'cmd') && get(a:node.ea.cmd, 'name', '') ==# 'let'
    call self.error_mes(a:node, 'EVL207', 'statement with no effect', a:node)
    return
  endif

  " command を引数にとるものは skip する.
  let str = vimlint#util#skip_modifiers_excmd(a:node.str)

  let s = vimlint#util#req_parse_excmd(str)
  if s !=# ''
    let ref = (s =~# '^exe\%[cute]') ? 2 : 1
    call self.parse_string(s, a:node, 'excmd', ref)
    return
  endif

  "  redir => res, redir =>> res
  let s = matchstr(a:node.str, '\s*redi[r]\?\s\+=>[>]\?\s*\zs.*\ze\s*')
  if s !=# '' && s !=# 'END'
    let a:node.type = s:vlp.NODE_IDENTIFIER
    let a:node.value = s
    call self.append_var(self.env, a:node, s:vlp.NIL, 'redir')
    return
  endif

  let s = substitute(a:node.str, '\s', '', 'g')
  " call つけて parse しなおしたほうが良いだろうけど.
  if a:node.str !~# '^\s*\w\+\s\+\w' &&
  \  s =~# '^\([gbwtsl]:\)\?[#A-Za-z0-9_]\+\(\.\w\+\|\[.*\]\)*(.*)$'
    call self.error_mes(a:node, 'EVL202', 'missing call `' . s . '`', 1)
  endif

endfunction "}}}

" 関数名. よくわからんのは '' を返す
function! s:get_funcname(self, node) abort " {{{
  if a:node.type == s:vlp.NODE_IDENTIFIER
    return a:node.value
  endif
  if a:node.type == s:vlp.NODE_DOT
    return 'a' . '.' . s:get_funcname(a:self, a:node.right)
  endif
  if a:node.type == s:vlp.NODE_SUBSCRIPT
    return ''
  endif
  if a:node.type == s:vlp.NODE_CURLYNAME
    return ''
  endif

  call a:self.error_mes(a:node, 'EVL901', 'unknown type `' . a:node.type . '` in get_funcname()', 1)
  return ''
endfunction " }}}

function s:VimlLint.compile_function(node, refchk) abort "{{{
  " @TODO left が dot/subs だった場合にのみ self は予約語とする #5
  let left = self.compile(a:node.left, 0) " name of function
  let funcname = s:get_funcname(self, left)
  if funcname =~# ':' && funcname !~# '^s:' && funcname !~# '^g:[A-Z]'
    " https://groups.google.com/forum/#!topic/vim_dev/iZMnLrMXEZM/discussion
    "  A function name should not be allowed to contain a colon.
    "  The intention, as mentioned in the quoted docs,  is only alphanumeric
    "  characters and '_', while prepending s: is allowed to make the function
    "  script-local.  Something like abc:def() was never intended to work.
    call self.error_mes(left, 'EVL107', 'A function name is not allowed to contain a colon: `' . funcname . '`', 1)
  endif

  if self.param.func_abort && !a:node.attr.abort
    call self.error_mes(a:node, 'EVL110', 'function ' . funcname . ' does not have the abort argument', 1)
  endif

  let rlist = map(a:node.rlist, 'self.compile(v:val, 0)')  " list of argument string

  let self.env = s:env(self.env, left, a:node.attr.dict ||
        \ left.type == s:vlp.NODE_DOT || left.type == s:vlp.NODE_SUBSCRIPT)
  if a:node.attr.range
    call s:append_var_(self.env, 'a:firstline', a:node, a:node, 1)
    call s:append_var_(self.env, 'a:lastline', a:node, a:node, 1)
  endif
  for v in rlist
    " E853 if Duplicate argument
    call self.append_var(self.env, v, s:vlp.NIL, 'a:')
    unlet v
  endfor
  call self.compile_body(a:node.body, 1)

  " 未使用変数は?
  if a:node.attr.range
    " issue #76
    if self.env.var['a:firstline'].ref || self.env.var['a:lastline'].ref
      let self.env.var['a:firstline'].ref = 1
      let self.env.var['a:lastline'].ref = 1
    endif
  endif

  for v in filter(keys(self.env.var), 'self.env.var[v:val].ref == 0')
    " a: は例外とする, オプションが必要 @TODO
"      echo self.env.var[v]
    if v =~# '^a:'
      call self.error_mes(self.env.var[v].node, 'EVL103', 'unused argument `' . v . '`', v)
    else
      call self.error_mes(self.env.var[v].node, 'EVL102', 'unused variable `' . v . '`', v)
    endif
  endfor

  let self.env = self.env.outer
endfunction " }}}

" @vimlint(EVL103, 1, a:node)
function s:VimlLint.compile_delfunction(node, refchk) abort " {{{
  " @TODO function は定義済か?
endfunction " }}}
" @vimlint(EVL103, 0, a:node)

function s:VimlLint.compile_return(node, refchk) abort " {{{

  if self.env == self.env.global
    call self.error_mes(a:node, 'E133', ':return not inside a function', 1)
  elseif a:node.left is s:vlp.NIL
    let self.env.ret = 1
  else
    call self.compile(a:node.left, 1)
    let self.env.ret = 1
  endif
endfunction " }}}

function s:VimlLint.compile_excall(node, refchk) abort " {{{
  return self.compile(a:node.left, a:refchk)
endfunction " }}}

function s:VimlLint.compile_let(node, refchk) abort " {{{
  " if type(a:node.right) != type({})
  "   echo "compile_let. right is invalid"
  "   echo a:node
  " endif
  let right = self.compile(a:node.right, 1)

  if a:node.left isnot s:vlp.NIL
    let left = self.compile(a:node.left, 0)
    if s:readonly_var(left)
      call self.error_mes(left, 'E46', 'Cannot change read-only variable ' . left.value, 1)
    else
      call self.append_var(self.env, left, right, 'le1')
    endif
  else
    let list = map(a:node.list, 'self.compile(v:val, 0)')
    call map(list, 'self.append_var(self.env, v:val, right, "letn")')
    if a:node.rest isnot s:vlp.NIL
      let v = self.compile(a:node.rest, 0)
      if s:readonly_var(v)
        call self.error_mes(v, 'E46', 'Cannot change read-only variable ' . v.value, 1)
      else
        call self.append_var(self.env, v, right, 'letr')
      endif
    endif
  endif
endfunction " }}}

function s:VimlLint.compile_unlet(node, refchk) abort "{{{
  " @TODO unlet! の場合には存在チェック不要
  let f = a:node.ea.forceit ? 0 : 1
  let list = map(a:node.list, 'self.compile(v:val, ' . f . ')')
  for v in list
    " unlet
    call s:delete_var(self.env, v) " f
  endfor
endfunction "}}}

function s:VimlLint.compile_lockvar(node, refchk) abort "{{{
  for var in a:node.list
    if var.type != s:vlp.NODE_IDENTIFIER
"      call self.error_mes(a:node, "Ex#, 'lockvar: internal variable is required: ' . var, 1)
    else
      call vimlint#exists_var(self, self.env, var, 0, 0)
"      call self.error_mes(a:node, "Ex#, 'undefined variable: ' . var, 1)
    endif
  endfor
endfunction "}}}

function s:VimlLint.compile_unlockvar(node, refchk) abort "{{{
  for var in a:node.list
    if var.type != s:vlp.NODE_IDENTIFIER
"      call self.error_mes(a:node, 'lockvar: internal variable is required: ' . var, 1)
    else
      call vimlint#exists_var(self, self.env, var, 0, 0)
"      call self.error_mes(a:node, 'undefined variable: ' . var, 1)
    endif
  endfor
endfunction "}}}

function! s:neg_exists(ex) abort " {{{
  let a = a:ex
  if len(a) == 0
    return a
  endif
  let stack = [a]
  while len(stack) > 0
    let b = remove(stack, -1)
    if len(b) == 0
      continue
    elseif b[1] ==# 'e'
      let b[0] = !b[0]
      continue
    else
      let stack += b[2]
    endif
  endwhile

  return a
endfunction " }}}

function! s:VimlLint.extract_exists(cond) abort " {{{
  " @return a list of {type:and/or/exists, bool, var]
  " これ以外はしらない
  " exists()
  " !exists()
  " exists != 0
  " exists == 0
  " call vimlint#debug#echonode(a:cond, 0)
  if a:cond.type == s:vlp.NODE_EQUAL ||
      \  a:cond.type == s:vlp.NODE_NEQUAL
    if a:cond.left == a:cond.right
      return []
    endif
    if a:cond.left.type == s:vlp.NODE_NUMBER
      let l = a:cond.right
      let r = a:cond.left
    else
      let l = a:cond.left
      let r = a:cond.right
    endif

    if r.type != s:vlp.NODE_NUMBER || r.value != 0
      return []
    endif

    if l.type != s:vlp.NODE_CALL
      return []
    endif
    let a = s:VimlLint.extract_exists(l)
    if len(a) == 0
      return a
    elseif a:cond.type == s:vlp.NODE_EQUAL
      let a[0] = !a[0]
      return a
    else
      return a
    endif
  elseif a:cond.type == s:vlp.NODE_CALL
    let l = a:cond.left
    if l.type != s:vlp.NODE_IDENTIFIER || l.value !=# 'exists'
      return []
    endif

    let r = a:cond.rlist[0]
    if r.type != s:vlp.NODE_STRING
      return []
    endif
    return [1, 'e', r.value]
  elseif a:cond.type == s:vlp.NODE_AND ||
        \ a:cond.type == s:vlp.NODE_OR
    let a = []
    for lr in [s:VimlLint.extract_exists(a:cond.left),
            \ s:VimlLint.extract_exists(a:cond.right)]
      if len(lr) == 0
        continue
      elseif lr[1] !=# 'e' && lr[0] == (a:cond.type == s:vlp.NODE_AND)
        let a += lr[2]
      else
        let a += [lr]
      endif
    endfor
    return [a:cond.type == s:vlp.NODE_AND, 'ao', a]
  elseif a:cond.type == s:vlp.NODE_NOT
    let a = s:VimlLint.extract_exists(a:cond.left)
    return s:neg_exists(a)
  endif

  return []
endfunction " }}}

function s:VimlLint.check_exists(ex, cond) abort " {{{

  let a = a:ex
  if len(a) == 0
    return
  endif

  if a[1] ==# 'e'
    " if exists()
    let a = [a]
  elseif a[0]
    " if exists() && exists() && ...
    let a = a[2]
  else
    " if exists() || exists() ||
    " not supported
    return
  endif

  for b in a
    if b[1] ==# 'e' && b[0] && b[2][1] =~# '[A-Za-z0-9_]'
      " append する.
      " @see :h exists()
      let name = b[2][1 : -2]
      if name !~# '^[gbwtslva]:' && name !~# '#'
        " prefix なし.
        if self.env == self.env.global
          let name = 'g:' . name
        endif
      endif
      " lockvar はやらない
      if name !~# '^a:' || self.env == self.env.global
        " @TODO 今は変数の中身は参照していないので適当に代入可能
        call self.parse_string(name, a:cond, 'exists', 0)
      endif
    endif
  endfor
endfunction " }}}

function s:VimlLint.compile_if(node, refchk) abort "{{{
"  call s:VimlLint.error_mes(a:node, "compile_if")
  let cond = self.compile(a:node.cond, 2) " if ()
  let tcond = cond


  if cond.type == s:vlp.NODE_NUMBER
      call self.error_mes(a:node, 'EVL204', 'constant in conditional context', 1)
  endif

  let p = len(self.env.varstack)
  let ex = [self.extract_exists(cond)]
  "echo "if" . string(ex)
  call self.check_exists(ex[-1], cond)
  call self.compile_body(a:node.body, a:refchk)

  call s:restore_varstack(self.env, p, 'if1')

  let pos = [s:gen_pos_cntl(self.env, p)]
  call s:reset_env_cntl(self.env)

  for node in a:node.elseif

    let cond = self.compile(node.cond, 2) " if ()
    let tcond = {'type' : s:vlp.NODE_OR, 'left' : tcond, 'right' : cond}

    if cond.type == s:vlp.NODE_NUMBER
        call self.error_mes(a:node, 'EVL204', 'constant in conditional context', 1)
    endif

    call self.compile(node.cond, 2)
    let p = len(self.env.varstack)

    let ex += [self.extract_exists(cond)]
    "echo "elif" . string(ex)
    call self.check_exists(ex[-1], cond)
    call self.compile_body(node.body, a:refchk)
    call s:restore_varstack(self.env, p, 'if2')

    let pos += [s:gen_pos_cntl(self.env, p)]
    call s:reset_env_cntl(self.env)
  endfor

  let p = len(self.env.varstack)

  if a:node.else isnot s:vlp.NIL
    " else
    let ex = filter(ex, 'len(v:val) > 0')
    if len(ex) == 0
    elseif len(ex) == 1
      let ex = ex[0]
    else
      let ex = [0, 'ao', ex]
    endif
    "echo "else" . string(ex)
    call self.check_exists(s:neg_exists(ex), cond)
    call self.compile_body(a:node.else.body, a:refchk)
    call s:restore_varstack(self.env, p, 'if3')
  endif

  let pos += [s:gen_pos_cntl(self.env, p)]
  call s:reset_env_cntl(self.env)

  " reconstruct
  " let して return した、は let していないにする
"  call vimlint#debug#decho("call reconstruct _ifs: " . string(a:node.pos))
  call s:reconstruct_varstack(self, self.env, pos, 0, 'if') " if
"  call vimlint#debug#decho("call reconstruct _ife: " . string(a:node.pos))

endfunction "}}}

function s:VimlLint.compile_while(node, refchk) abort "{{{
  let cond = self.compile(a:node.cond, 1)
  if cond.type == s:vlp.NODE_NUMBER
    " while 0
    if str2nr(cond.value) == 0
      if len(a:node.body) > 0
        let node = a:node.body[0]
      else
        let node = a:node
      endif
      call self.error_mes(node, 'EVL201', 'unreachable code: while', 1)
      return
    endif
  endif

  call self.compile_loop(a:node, a:refchk, cond.type != s:vlp.NODE_NUMBER, 'while')
endfunction "}}}

function s:VimlLint.compile_for(node, refchk) abort "{{{
  " VAR が変数のリスト、または変数であることは, vimlparser がチェックしている
  " right がリストであることはチェックしていない.
  " for VAR in LIST
  "   BODy
  " endfor
  let right = self.compile(a:node.right, 1) " LIST
  if right.type == s:vlp.NODE_NUMBER ||
  \  right.type == s:vlp.NODE_DICT ||
  \  right.type == s:vlp.NODE_STRING
    call self.error_mes(right, 'E714', 'List required', 1)
    return
  endif

  if right.type == s:vlp.NODE_LIST
    if len(right.value) == 0
      if len(a:node.body) > 0
        let node = a:node.body[0]
      else
        let node = right
      endif
      call self.error_mes(node, 'EVL201', 'unreachable code: for', 1)
      return
    endif
  endif

  if a:node.left isnot s:vlp.NIL " for {var} in {list}
    let left = self.compile(a:node.left, 0)
    call self.append_var(self.env, left, right, 'for')
    " append
"    echo "compile for, left is"
"    echo left
  else
    " for [{var1},...] in {listlist}
    let list = map(a:node.list, 'self.compile(v:val, 0)')
    call map(list, 'self.append_var(self.env, v:val, right, "forn")')

    " append
    if a:node.rest isnot s:vlp.NIL
      let rest = self.compile(a:node.rest, 0)
      call self.append_var(self.env, rest, right, 'forr')
    endif
  endif

  call self.compile_loop(a:node, a:refchk, right.type != s:vlp.NODE_LIST, 'for')
endfunction "}}}

function s:VimlLint.compile_loop(node, refchk, noloop, kind) abort "{{{
  let bak = [self.env.loopb, self.env.has_break]
  let self.env.loopb = 0
  let self.env.has_break = 0

  let self.env.global.loop += 1

  " for/while 文の中
  let p = len(self.env.varstack)
  call self.compile_body(a:node.body, 1)

  call s:restore_varstack(self.env, p, a:kind)
  let pos = [s:gen_pos_cntl(self.env, p)]
  call s:reset_env_cntl(self.env)

  if a:noloop
    " for/while にはいらなかった場合
    " ループ条件がはじめから false な場合
    let p = len(self.env.varstack)
    let pos += [s:gen_pos_cntl(self.env, p)]
  endif

  "call vimlint#debug#decho("call reconstruct _fors: " . string(a:node.pos))
  call s:reconstruct_varstack(self, self.env, pos, 1, a:kind) " loop(for/while)
  "call vimlint#debug#decho("call reconstruct _fore: " . string(a:node.pos))

  " loop 内の break/continue 情報は意味がないため
  let self.env.loopb = bak[0]
  let self.env.has_break = bak[1]
  let self.env.global.loop -= 1
endfunction "}}}

function s:VimlLint.compile_continue(node, refchk) abort "{{{
  if self.env.global.loop <= 0
    " vimlparser....
    call self.error_mes(a:node, 'E586', ':continue without :while or :for: continue', 1)
  else
    let self.env.loopb = 1
    let self.env.has_break = 1
  endif
endfunction "}}}

function s:VimlLint.compile_break(node, refchk) abort "{{{
  if self.env.global.loop <= 0
    call self.error_mes(a:node, 'E587', ':break without :while or :for: break', 1)
  else
    let self.env.loopb = 1
    let self.env.has_break = 1
  endif
endfunction "}}}

function s:VimlLint.compile_try(node, refchk) abort "{{{

  let p = len(self.env.varstack)
  call self.compile_body(a:node.body, a:refchk)

  if a:node.finally isnot s:vlp.NIL
    let self.env.global.fins += 1
  endif

  let ret = self.env.ret
  let loopb = self.env.loopb
  call s:reset_env_cntl(self.env)

  " try 句はどこで抜けるかわからないため
  " 定義したすべての変数は定義されているかも状態,
  " つまり stat=1 にする.
  call s:reconstruct_varstack_st(self, self.env, 0)

  let pos = []
  for node in a:node.catch
    " catch 部. error が起こるのは try 部の最初と仮定してしまって良いか?
    let p = len(self.env.varstack)

    if node.pattern isnot s:vlp.NIL
      call self.compile_body(node.body, a:refchk)
    else
      call self.compile_body(node.body, a:refchk)
    endif

    call s:restore_varstack(self.env, p, 'cth')

    let pos += [s:gen_pos_cntl(self.env, p)]
    call s:reset_env_cntl(self.env)

  endfor

  " @TODO

  call s:reconstruct_varstack(self, self.env, pos, 0, 'try')

  " backup env
  let retc = self.env.ret
  let loopbc = self.env.loopb

  call s:reset_env_cntl(self.env)

  if a:node.finally isnot s:vlp.NIL
    let self.env.global.fins -= 1
    call self.compile_body(a:node.finally.body, a:refchk)
  endif

  let self.env.ret = (ret && retc)
  let self.env.loopb = (loopb && loopbc)

endfunction "}}}

function s:VimlLint.compile_throw(node, refchk) abort "{{{
  call self.compile(a:node.left, 1)
  " return みたいなものでしょう.
  let self.env.ret = 1
endfunction "}}}

function s:VimlLint.compile_echo(node, refchk) abort "{{{
  call map(a:node.list, 'self.compile(v:val, 1)')
endfunction "}}}

function s:VimlLint.compile_echon(node, refchk) abort "{{{
  call map(a:node.list, 'self.compile(v:val, 1)')
endfunction "}}}

function s:VimlLint.compile_echohl(...) abort "{{{
"   " @TODO
endfunction "}}}

function s:VimlLint.compile_echomsg(node, refchk) abort "{{{
  call map(a:node.list, 'self.compile(v:val, 1)')
endfunction "}}}

function s:VimlLint.compile_echoerr(node, refchk) abort "{{{
  call map(a:node.list, 'self.compile(v:val, 1)')
endfunction "}}}

function s:VimlLint.compile_execute(node, refchk) abort "{{{
  " @TODO execute :e `=path`
  call map(a:node.list, 'self.compile(v:val, 1)')
endfunction "}}}

" expr1: expr2 ? expr1 : expr1
function s:VimlLint.compile_ternary(node, refchk) abort "{{{
  let a:node.cond = self.compile(a:node.cond, 1)
  let a:node.left = self.compile(a:node.left, 1)
  let a:node.right = self.compile(a:node.right, 1)
  return a:node
endfunction "}}}

" op2 {{{
function s:VimlLint.compile_or(node, ...) abort
  return self.compile_op2(a:node, 'or')
endfunction

function s:VimlLint.compile_and(node, ...) abort
  return self.compile_op2(a:node, 'and')
endfunction

function s:VimlLint.compile_equal(node, ...) abort
  return self.compile_op2(a:node, '==')
endfunction

function s:VimlLint.compile_equalci(node, ...) abort
  return self.compile_op2(a:node, '==?')
endfunction

function s:VimlLint.compile_equalcs(node, ...) abort
  return self.compile_op2(a:node, '==#')
endfunction

function s:VimlLint.compile_nequal(node, ...) abort
  return self.compile_op2(a:node, '!=')
endfunction

function s:VimlLint.compile_nequalci(node, ...) abort
  return self.compile_op2(a:node, '!=?')
endfunction

function s:VimlLint.compile_nequalcs(node, ...) abort
  return self.compile_op2(a:node, '!=#')
endfunction

function s:VimlLint.compile_greater(node, ...) abort
  return self.compile_op2(a:node, '>')
endfunction

function s:VimlLint.compile_greaterci(node, ...) abort
  return self.compile_op2(a:node, '>?')
endfunction

function s:VimlLint.compile_greatercs(node, ...) abort
  return self.compile_op2(a:node, '>#')
endfunction

function s:VimlLint.compile_gequal(node, ...) abort
  return self.compile_op2(a:node, '>=')
endfunction

function s:VimlLint.compile_gequalci(node, ...) abort
  return self.compile_op2(a:node, '>=?')
endfunction

function s:VimlLint.compile_gequalcs(node, ...) abort
  return self.compile_op2(a:node, '>=#')
endfunction

function s:VimlLint.compile_smaller(node, ...) abort
  return self.compile_op2(a:node, '<')
endfunction

function s:VimlLint.compile_smallerci(node, ...) abort
  return self.compile_op2(a:node, '<?')
endfunction

function s:VimlLint.compile_smallercs(node, ...) abort
  return self.compile_op2(a:node, '<#')
endfunction

function s:VimlLint.compile_sequal(node, ...) abort
  return self.compile_op2(a:node, '<=')
endfunction

function s:VimlLint.compile_sequalci(node, ...) abort
  return self.compile_op2(a:node, '<=?')
endfunction

function s:VimlLint.compile_sequalcs(node, ...) abort
  return self.compile_op2(a:node, '<=#')
endfunction

function s:VimlLint.compile_match(node, ...) abort
  return self.compile_op2(a:node, 'match')
endfunction

function s:VimlLint.compile_matchci(node, ...) abort
  return self.compile_op2(a:node, 'matchci')
endfunction

function s:VimlLint.compile_matchcs(node, ...) abort
  return self.compile_op2(a:node, 'matchcs')
endfunction

function s:VimlLint.compile_nomatch(node, ...) abort
  return self.compile_op2(a:node, 'nomatch')
endfunction

function s:VimlLint.compile_nomatchci(node, ...) abort
  return self.compile_op2(a:node, 'nomatchci')
endfunction

function s:VimlLint.compile_nomatchcs(node, ...) abort
  return self.compile_op2(a:node, 'nomatchcs')
endfunction

function s:VimlLint.compile_is(node, ...) abort
  return self.compile_op2(a:node, 'is')
endfunction

function s:VimlLint.compile_isci(node, ...) abort
  return self.compile_op2(a:node, 'is?')
endfunction

function s:VimlLint.compile_iscs(node, ...) abort
  return self.compile_op2(a:node, 'is#')
endfunction

function s:VimlLint.compile_isnot(node, ...) abort
  return self.compile_op2(a:node, 'is not')
endfunction

function s:VimlLint.compile_isnotci(node, ...) abort
  return self.compile_op2(a:node, 'isnot?')
endfunction

function s:VimlLint.compile_isnotcs(node, ...) abort
  return self.compile_op2(a:node, 'isnot#')
endfunction

function s:VimlLint.compile_add(node, ...) abort
  let r = self.compile_op2(a:node, '+')
  if vimlint#util#notnum_type(r.left) && vimlint#util#notlist_type(r.left) ||
  \  vimlint#util#notnum_type(r.right) && vimlint#util#notlist_type(r.right)
    call self.error_mes(r, 'EVL206', '`+` operator can be used for Number addition or List concatenation', r)
  endif
  return r
endfunction

function s:VimlLint.compile_subtract(node, ...) abort
  let r = self.compile_op2(a:node, '-')
  if vimlint#util#notnum_type(r.left) || vimlint#util#notnum_type(r.right)
    call self.error_mes(r, 'EVL206', '`-` operator can be used for Number subtraction', r)
  endif
  return r
endfunction

function s:VimlLint.compile_concat(node, ...) abort
  let r = self.compile_op2(a:node, '.')
  " google style guide. use spaces around operators
  let line = self.lines[r.pos.lnum - 1]
  if line[r.pos.col - 2] !~# '\s' || len(line) > r.pos.col && line[r.pos.col] !~# '\s'
    if self.filename !=# ''
      call self.error_mes(r, 'EVL301', 'use space around operator `.`', r)
    endif
  endif
  return r
endfunction

function s:VimlLint.compile_multiply(node, ...) abort
  let r = self.compile_op2(a:node, '*')
  if vimlint#util#notnum_type(r.left) || vimlint#util#notnum_type(r.right)
    call self.error_mes(r, 'EVL206', '`*` operator can be used for Number multipliction', r)
  endif
  return r
endfunction

function s:VimlLint.compile_divide(node, ...) abort
  let r = self.compile_op2(a:node, '/')
  if vimlint#util#notnum_type(r.left) || vimlint#util#notnum_type(r.right)
    call self.error_mes(r, 'EVL206', '`/` operator can be used for Number division', r)
  endif
  return r
endfunction

function s:VimlLint.compile_remainder(node, ...) abort
  let r = self.compile_op2(a:node, '%')
  if vimlint#util#notnum_type(r.left) || vimlint#util#notnum_type(r.right)
    call self.error_mes(r, 'EVL206', '`%` operator can be used for Number modulo', r)
  endif
  return r
endfunction
" }}}

" op1 {{{
function s:VimlLint.compile_not(node, ...) abort
  return self.compile_op1(a:node, 'not ')
endfunction

function s:VimlLint.compile_plus(node, ...) abort
  return self.compile_op1(a:node, '+')
endfunction

function s:VimlLint.compile_minus(node, ...) abort
  return self.compile_op1(a:node, '-')
endfunction
" }}}

function! s:escape_string(str) abort "{{{
  return eval(a:str)
endfunction "}}}

function s:VimlLint.parse_string(str, node, cmd, ref) abort "{{{
  try
    let p = s:vlp.VimLParser.new()
    let param = copy(self.param)
    let c = s:VimlLint.new(param)
    let c.env = self.env
    let c.filename = self.filename
    let pos = vimlint#util#get_pos(a:node)
    let lines = range(pos.lnum - 1)
    let lines = map(lines, '""')
"    let r = s:vlp.StringReader.new(a:str)
    if a:ref == 1
      let lines += ['echo ' . a:str]
    elseif a:ref == 2
      let lines += [a:str]
    else
      let lines += ['let ' . a:str . ' = 1']
      " @TODO 今は変数の中身は参照していないので適当に代入可能
    endif
    let r = s:vlp.StringReader.new(lines)
    let c.lines = lines
    call c.compile(p.parse(r), 1)
  catch
    call self.error_mes(a:node, 'EVL203', 'parse error in `' . a:cmd . '`', 1)
  endtry
endfunction "}}}

function s:VimlLint.compile_call(node, refchk) abort "{{{
  let rlist = map(a:node.rlist, 'self.compile(v:val, 1)')
  let a:node.rlist = rlist
  let left = self.compile(a:node.left, 0)
  " 関数名がそのまま left.value に入っている..
  if has_key(left, 'value') && type(left.value) == type('')
    let d = vimlint#builtin#get_func_inf(left.value)
    if d != {}
"     call s:__called(left.value)
      if len(rlist) < d.min
        call self.error_mes(left, 'E119', 'Not enough arguments for function: ' . left.value, 1)
      elseif len(rlist) > d.max
        call self.error_mes(left, 'E118', 'Too many arguments for function: ' . left.value, 1)
      else
"        for i in range(len(rlist))
          " 型チェック
"        endfor
        call vimlint#builtin_arg#check(self, left.value, a:node)
      endif
    elseif left.value =~# '^[gl]:[a-z][A-Za-z0-9_]\+$'
      call self.error_mes(left, 'E117', 'Unknown function: `' . left.value . '`', 1)
"    elseif left.value =~# '^[A-Z][A-Za-z0-9_]*$' && self.env.global != self.env
"      call vimlint#exists_var(self, self.env, left, 1, 0)
    elseif left.value =~# '^\%([la]:\)\?[A-Za-z0-9_]\+$'
      if left.value =~# '^\(l:\)\?[A-Z]'
        let funcname = substitute(left.value, '^l:', '', '')
        if has_key(self.env.no_prepend_var, funcname)
          let n = self.env.no_prepend_var[funcname]
          call self.error_mes(n, 'EVL111', 'variable `' . funcname . '` is used without prefix', funcname)
        endif
      endif

      " variable? 参照しましたよ.
      " 新しい関数がでたらどうする？
      " @TODO local function が EVL101 になってしまうので gbwtsla にしない
      call vimlint#exists_var(self, self.env, left, 1, 0)
    endif

    " @TODO vital... はどうしよう
    " 引数誤りはチェック済, にする.

  endif

  return a:node
"  return {'type' : 'call', 'l' : left, 'r' : rlist, 'node' : a:node}
endfunction "}}}

" subst slice
" :let l = mylist[:3]             " first four items
" :let l = mylist[4:4]            " List with one item
" :let l = mylist[:]              " shallow copy of a List
function s:VimlLint.compile_slice(node, refchk) abort " {{{
  for i in range(len(a:node.rlist))
    let r = a:node.rlist[i] is s:vlp.NIL ? s:vlp.NIL : self.compile(a:node.rlist[i], 1)
    let a:node.rlist[i] = r
    unlet r
  endfor
  let a:node.left = self.compile(a:node.left, 1)
  return a:node
"  return {'type' : 'slice', 'l' : left, 'r' : [r0,r1], 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_subscript(node, ...) abort " {{{
  let a:node.left = self.compile(a:node.left, 1)
  let a:node.right = self.compile(a:node.right, 1)
  if a:node.right.type == s:vlp.NODE_IDENTIFIER
    if a:node.right.value =~# '^[gbwtslv]:$'
      call self.error_mes(a:node.right, 'E731', 'using Dictionary as a String', 1)
    endif
  endif
  return a:node

  " @TODO left is a list or a dictionary
"  return {'type' : 'subs', 'l' : left, 'r' : right, 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_dot(node, refchk) abort " {{{
  let a:node.left = self.compile(a:node.left, 1)
  let a:node.right = self.compile(a:node.right, 0)

  return a:node
"  return {'type' : 'subs', 'l' : left, 'r' : right, 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_number(node, ...) abort " {{{
  return a:node
"  return { 'type' : 'integer', 'val' : a:node.value, 'node' : a:node}
endfunction " }}}

" map の引数などをどう処理するか?
function s:VimlLint.compile_string(node, ...) abort " {{{
  return a:node
"  return { 'type' : 'string', 'val' : a:node.value, 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_list(node, refchk) abort " {{{
  let a:node.value = map(a:node.value, 'self.compile(v:val, 1)')
  return a:node
"  return { 'type' : 'list', 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_dict(node, refchk) abort " {{{
  " @TODO 文字列のみ
  for i in range(len(a:node.value))
    let v = a:node.value[i]
    let v[0] = self.compile(v[0], 1)
    let v[1] = self.compile(v[1], 1)
  endfor
  return a:node
"  return { 'type' : 'dict', 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_option(node, ...) abort " {{{
  return a:node
"  return { 'type' : 'option', 'node' : a:node}
endfunction " }}}

function! s:readonly_var(var) abort " {{{
  if a:var.type == s:vlp.NODE_IDENTIFIER
    if a:var.value =~# '^a:'
      return 1
    endif

    if a:var.value =~# '^[gbwtsl]:$'
      return 1
    endif
  endif
endfunction " }}}

function! s:reserved_name(name, is_dic_func) abort " {{{
  if a:name =~# '^\(a:\d\|[gbwtsla]:$\)' ||
  \  a:name ==# 'v:val' || a:name ==# 's:' ||
  \  (a:name =~# '\(l:\)\?self' && a:is_dic_func)
    " @TODO 'self' if a function is defined with the "dict" attribute
    return 1
  endif

  return 0
endfunction " }}}

function s:VimlLint.compile_identifier(node, refchk) abort " {{{
  let name = a:node.value
  if a:refchk && !s:reserved_name(name, self.env.is_dic_func)
    call vimlint#exists_var(self, self.env, a:node, 0, 0)
"    call self.error_mes(a:node, 'EVLx', 'undefined variable: ' . name, 1)
  elseif name ==# 'l:' && self.env.global == self.env
    " 予約語なので定義済みチェックは不要なため
    " exist_var を呼び出さないため例外処理
    call self.error_mes(a:node, 'EVL109', 'local variable `l:` is used outside of a function', name)
  endif

  return a:node
"  return {'type' : 'id', 'val' : name, 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_curlyname(node, refchk) abort " {{{
  for f in a:node.value
    if f.curly
      call self.compile(f.value, 1)
    endif
  endfor

  return a:node
"  return {'type' : 'curly', 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_env(node, refchk) abort " {{{
  return a:node
"  return {'type' : 'env', 'node' : a:node}
endfunction " }}}
" @vimlint(EVL103, 0, a:refchk)

" register
function s:VimlLint.compile_reg(node, ...) abort " {{{
  return a:node
"  return {'type' : 'reg', 'val' : a:node.value, 'node' : a:node}
"  echo a:node
"  throw 'NotImplemented: reg'
endfunction " }}}

" @vimlint(EVL103, 1, a:op)
function s:VimlLint.compile_op1(node, op) abort " {{{
  let a:node.left = self.compile(a:node.left, 1)
  return a:node
endfunction " }}}
" @vimlint(EVL103, 0, a:op)

" @vimlint(EVL103, 1, a:op)
function s:VimlLint.compile_op2(node, op) abort " {{{
  let a:node.left = self.compile(a:node.left, 1)
  let a:node.right = self.compile(a:node.right, 1)
  return a:node

  " @TODO 比較/演算できる型どうしか.
  " @TODO 演算結果の型を返すようにする
endfunction " }}}
" @vimlint(EVL103, 0, a:op)

function! s:vimlint_file(filename, param, progress) abort " {{{
  let vimfile = a:filename
  let p = s:vlp.VimLParser.new()
  let c = s:VimlLint.new(a:param)
  try
    if a:param.type ==# 'string'
        let r = s:vlp.StringReader.new(vimfile)
        let c.filename = ''
        let c.lines = split(vimfile, "\n")
    else
        let l = readfile(vimfile)
        let r = s:vlp.StringReader.new(l)
        let c.filename = vimfile
        let c.lines = l
    endif


    if c.filename !=# '' && a:param.parse_py
      call vimlint#util#echo_progress(a:param, a:progress . c.filename . ' start.py')
      let py = globpath(&rtp, 'bin/vimlparser-vimlint.py')
      let fv = tempname()
      silent execute 'new' vimfile
      silent execute ':w ++enc=utf-8' fv
      :quit!
      let f = tempname()
      call system(printf('python3 %s %s %s', py, fv, f))
      call vimlint#util#echo_progress(a:param, a:progress . c.filename . ' source.py')
      source `=f`
      let vp = g:Vimlint_Parse_Ret(s:vlp.NIL)
      if type(vp) == type('')
        throw vp
      endif
    else
      call vimlint#util#echo_progress(a:param, a:progress . c.filename . ' start')
      let vp = p.parse(r)
    endif


    call vimlint#util#echo_progress(a:param, a:progress . c.filename . ' check')

    call c.compile(vp, 1)

    " global 変数(s:)のチェック
    let env = c.env
    for v in keys(env.var)
      if env.var[v].subs == 0 && env.extend == 0
        call c.error_mes(env.var[v].node, 'EVL101', 'undefined variable `' . v . '`', v)
      endif
    endfor

    call vimlint#util#check_scriptencoding(c, a:param.type ==# 'string' ? [vimfile] : readfile(vimfile))
  catch

    let line = matchstr(v:exception, '.*line \zs\d\+\ze col \d\+$')
    let col  = matchstr(v:exception, '.*line \d\+ col \zs\d\+\ze$')
    let i = 'EVP_0'
    if line ==# ''
      let msg = substitute(v:throwpoint, '\.\.\zs\d\+', '\=s:numtoname(submatch(0))', 'g') . "\n" . v:exception
    elseif matchstr(v:exception, 'vimlparser: E\d\+:') !=# ''
      let i = 'EVP_' . matchstr(v:exception, 'vimlparser: \zsE\d\+\ze:')
      let msg = matchstr(v:exception, '.*vimlparser: E\d\+: \zs.*\ze: line \d\+ col \d\+$')
    else
      let msg  = matchstr(v:exception, '.*vimlparser: \zs.*\ze: line \d\+ col \d\+$')

    endif

    call c.error_mes({'pos' : {'lnum' : line, 'col' : col, 'i' : i}}, i, msg, 1)
  finally

    for l:Hook in c.param.hook_after_0
      call Hook(a:filename, a:param, c)
    endfor

    call vimlint#util#echo_progress(a:param, a:progress . c.filename . ' end')
    return c.error
  endtry

endfunction " }}}

function! s:vimlint_dir(dir, param) abort " {{{
  if a:param.recursive
    let filess = glob(a:dir . '/**/*.vim')
  else
    let filess = glob(a:dir . '/*.vim')
  endif
  let fs = split(filess, "\n")
  let ret = []
  for i in range(len(fs))
    let ret += s:vimlint_file(fs[i], a:param, printf('(%2d/%d) ', i+1, len(fs)))
  endfor

  return ret
endfunction " }}}

function! s:get_param(p) abort " {{{
  let param = a:p
  if exists('g:vimlint#config') && type(g:vimlint#config) == type({})
    let param = extend(param, g:vimlint#config, 'keep')
  endif
  let param = extend(param, s:default_param, 'keep')
  let param.parse_py = param.parse_py ? executable('python3') : 0

  let param = s:extend_errlevel(param)
  let param.bak = deepcopy(param)

  let out_type = 'echo'
  if has_key(param, 'output') " {{{
    if type(param.output) == type('')
      if param.output ==# 'quickfix'
        unlet param.output
        let out_type = 'quickfix'
      else
        let param.output = {'filename' : param.output}
      endif
    elseif type(param.output) == type([])
      let out_type = 'list'
      unlet param.output
      let param.outfunc = function('vimlint#util#output_list')
    elseif type(param.output) == type(function('tr'))
      let out_type = 'function'
      let param.outfunc = param.output
      unlet param.output
    elseif type(param.output) != type({})
      unlet param.output
    endif

    if has_key(param, 'output')
      let param.output = extend(param.output, s:default_param_output, 'keep')
      if param.output.filename ==# ''
        unlet param.output
      else
        let out_type = 'file'
      endif
    endif
  endif


  if has_key(param, 'hook_after_0')
    unlet param.hook_after_0
  endif
  let param.hook_after_0 = []
  if out_type ==# 'file'
    " file
    let param.outfunc = function('vimlint#util#output_file')
    let param.hook_after_0 = [function('vimlint#util#hook_after_file')]
    if !param.output.append
      call writefile([], param.output.filename)
    endif
  elseif out_type ==# 'echo'
    let param.outfunc = function('vimlint#util#output_echo')
  elseif out_type ==# 'quickfix'
    call setqflist([], ' ')
    let param.outfunc = function('vimlint#util#output_quickfix')
    let param.hook_after_0 = [function('vimlint#util#hook_after_quickfix')]
  endif "}}}

  return param
endfunction " }}}

function! vimlint#vimlint(file, ...) abort " {{{

  let param = s:get_param(a:0 ? deepcopy(a:1) : {})

  let files = (type(a:file) == type([])) ? a:file : [a:file]
  let ret = []
  for f in files

    if param.type ==# 'string'
      let ret += s:vimlint_file(f, param, '.... ')
    elseif isdirectory(f)
      let ret += s:vimlint_dir(f, param)
    elseif filereadable(f)
      let ret += s:vimlint_file(f, param, '.... ')
    else
      echoerr 'vimlint: cannot readfile: ' . f
    endif
  endfor
  return ret
endfunction " }}}

function! s:numtoname(num) abort " {{{
  let sig = printf("function('%s')", a:num)
  for k in keys(s:)
    if type(s:[k]) == type({})
      for name in keys(s:[k])
        if type(s:[k][name]) == type(function('tr')) && string(s:[k][name]) == sig
          return printf('%s.%s', k, name)
        endif
      endfor
    endif
  endfor
  return a:num
endfunction " }}}

function! vimlint#command(config) abort " {{{
  let config = {}
  let [file, config] = vimlint#util#parse_cmdline(a:config, config)
  return vimlint#vimlint(file, config)
endfunction " }}}


let s:VimlLint.compile_funcs = repeat([0], 90)
let s:VimlLint.compile_funcs[s:vlp.NODE_TOPLEVEL] = s:VimlLint.compile_toplevel
let s:VimlLint.compile_funcs[s:vlp.NODE_COMMENT] = s:VimlLint.compile_comment
let s:VimlLint.compile_funcs[s:vlp.NODE_EXCMD] = s:VimlLint.compile_excmd
let s:VimlLint.compile_funcs[s:vlp.NODE_FUNCTION] = s:VimlLint.compile_function
let s:VimlLint.compile_funcs[s:vlp.NODE_DELFUNCTION] = s:VimlLint.compile_delfunction
let s:VimlLint.compile_funcs[s:vlp.NODE_RETURN] = s:VimlLint.compile_return
let s:VimlLint.compile_funcs[s:vlp.NODE_EXCALL] = s:VimlLint.compile_excall
let s:VimlLint.compile_funcs[s:vlp.NODE_LET] = s:VimlLint.compile_let
let s:VimlLint.compile_funcs[s:vlp.NODE_UNLET] = s:VimlLint.compile_unlet
let s:VimlLint.compile_funcs[s:vlp.NODE_LOCKVAR] = s:VimlLint.compile_lockvar
let s:VimlLint.compile_funcs[s:vlp.NODE_UNLOCKVAR] = s:VimlLint.compile_unlockvar
let s:VimlLint.compile_funcs[s:vlp.NODE_IF] = s:VimlLint.compile_if
let s:VimlLint.compile_funcs[s:vlp.NODE_WHILE] = s:VimlLint.compile_while
let s:VimlLint.compile_funcs[s:vlp.NODE_FOR] = s:VimlLint.compile_for
let s:VimlLint.compile_funcs[s:vlp.NODE_CONTINUE] = s:VimlLint.compile_continue
let s:VimlLint.compile_funcs[s:vlp.NODE_BREAK] = s:VimlLint.compile_break
let s:VimlLint.compile_funcs[s:vlp.NODE_TRY] = s:VimlLint.compile_try
let s:VimlLint.compile_funcs[s:vlp.NODE_THROW] = s:VimlLint.compile_throw
let s:VimlLint.compile_funcs[s:vlp.NODE_ECHO] = s:VimlLint.compile_echo
let s:VimlLint.compile_funcs[s:vlp.NODE_ECHON] = s:VimlLint.compile_echon
let s:VimlLint.compile_funcs[s:vlp.NODE_ECHOHL] = s:VimlLint.compile_echohl
let s:VimlLint.compile_funcs[s:vlp.NODE_ECHOMSG] = s:VimlLint.compile_echomsg
let s:VimlLint.compile_funcs[s:vlp.NODE_ECHOERR] = s:VimlLint.compile_echoerr
let s:VimlLint.compile_funcs[s:vlp.NODE_EXECUTE] = s:VimlLint.compile_execute
let s:VimlLint.compile_funcs[s:vlp.NODE_TERNARY] = s:VimlLint.compile_ternary
let s:VimlLint.compile_funcs[s:vlp.NODE_OR] = s:VimlLint.compile_or
let s:VimlLint.compile_funcs[s:vlp.NODE_AND] = s:VimlLint.compile_and
let s:VimlLint.compile_funcs[s:vlp.NODE_EQUAL] = s:VimlLint.compile_equal
let s:VimlLint.compile_funcs[s:vlp.NODE_EQUALCI] = s:VimlLint.compile_equalci
let s:VimlLint.compile_funcs[s:vlp.NODE_EQUALCS] = s:VimlLint.compile_equalcs
let s:VimlLint.compile_funcs[s:vlp.NODE_NEQUAL] = s:VimlLint.compile_nequal
let s:VimlLint.compile_funcs[s:vlp.NODE_NEQUALCI] = s:VimlLint.compile_nequalci
let s:VimlLint.compile_funcs[s:vlp.NODE_NEQUALCS] = s:VimlLint.compile_nequalcs
let s:VimlLint.compile_funcs[s:vlp.NODE_GREATER] = s:VimlLint.compile_greater
let s:VimlLint.compile_funcs[s:vlp.NODE_GREATERCI] = s:VimlLint.compile_greaterci
let s:VimlLint.compile_funcs[s:vlp.NODE_GREATERCS] = s:VimlLint.compile_greatercs
let s:VimlLint.compile_funcs[s:vlp.NODE_GEQUAL] = s:VimlLint.compile_gequal
let s:VimlLint.compile_funcs[s:vlp.NODE_GEQUALCI] = s:VimlLint.compile_gequalci
let s:VimlLint.compile_funcs[s:vlp.NODE_GEQUALCS] = s:VimlLint.compile_gequalcs
let s:VimlLint.compile_funcs[s:vlp.NODE_SMALLER] = s:VimlLint.compile_smaller
let s:VimlLint.compile_funcs[s:vlp.NODE_SMALLERCI] = s:VimlLint.compile_smallerci
let s:VimlLint.compile_funcs[s:vlp.NODE_SMALLERCS] = s:VimlLint.compile_smallercs
let s:VimlLint.compile_funcs[s:vlp.NODE_SEQUAL] = s:VimlLint.compile_sequal
let s:VimlLint.compile_funcs[s:vlp.NODE_SEQUALCI] = s:VimlLint.compile_sequalci
let s:VimlLint.compile_funcs[s:vlp.NODE_SEQUALCS] = s:VimlLint.compile_sequalcs
let s:VimlLint.compile_funcs[s:vlp.NODE_MATCH] = s:VimlLint.compile_match
let s:VimlLint.compile_funcs[s:vlp.NODE_MATCHCI] = s:VimlLint.compile_matchci
let s:VimlLint.compile_funcs[s:vlp.NODE_MATCHCS] = s:VimlLint.compile_matchcs
let s:VimlLint.compile_funcs[s:vlp.NODE_NOMATCH] = s:VimlLint.compile_nomatch
let s:VimlLint.compile_funcs[s:vlp.NODE_NOMATCHCI] = s:VimlLint.compile_nomatchci
let s:VimlLint.compile_funcs[s:vlp.NODE_NOMATCHCS] = s:VimlLint.compile_nomatchcs
let s:VimlLint.compile_funcs[s:vlp.NODE_IS] = s:VimlLint.compile_is
let s:VimlLint.compile_funcs[s:vlp.NODE_ISCI] = s:VimlLint.compile_isci
let s:VimlLint.compile_funcs[s:vlp.NODE_ISCS] = s:VimlLint.compile_iscs
let s:VimlLint.compile_funcs[s:vlp.NODE_ISNOT] = s:VimlLint.compile_isnot
let s:VimlLint.compile_funcs[s:vlp.NODE_ISNOTCI] = s:VimlLint.compile_isnotci
let s:VimlLint.compile_funcs[s:vlp.NODE_ISNOTCS] = s:VimlLint.compile_isnotcs
let s:VimlLint.compile_funcs[s:vlp.NODE_ADD] = s:VimlLint.compile_add
let s:VimlLint.compile_funcs[s:vlp.NODE_SUBTRACT] = s:VimlLint.compile_subtract
let s:VimlLint.compile_funcs[s:vlp.NODE_CONCAT] = s:VimlLint.compile_concat
let s:VimlLint.compile_funcs[s:vlp.NODE_MULTIPLY] = s:VimlLint.compile_multiply
let s:VimlLint.compile_funcs[s:vlp.NODE_DIVIDE] = s:VimlLint.compile_divide
let s:VimlLint.compile_funcs[s:vlp.NODE_REMAINDER] = s:VimlLint.compile_remainder
let s:VimlLint.compile_funcs[s:vlp.NODE_NOT] = s:VimlLint.compile_not
let s:VimlLint.compile_funcs[s:vlp.NODE_PLUS] = s:VimlLint.compile_plus
let s:VimlLint.compile_funcs[s:vlp.NODE_MINUS] = s:VimlLint.compile_minus
let s:VimlLint.compile_funcs[s:vlp.NODE_SUBSCRIPT] = s:VimlLint.compile_subscript
let s:VimlLint.compile_funcs[s:vlp.NODE_SLICE] = s:VimlLint.compile_slice
let s:VimlLint.compile_funcs[s:vlp.NODE_DOT] = s:VimlLint.compile_dot
let s:VimlLint.compile_funcs[s:vlp.NODE_CALL] = s:VimlLint.compile_call
let s:VimlLint.compile_funcs[s:vlp.NODE_NUMBER] = s:VimlLint.compile_number
let s:VimlLint.compile_funcs[s:vlp.NODE_STRING] = s:VimlLint.compile_string
let s:VimlLint.compile_funcs[s:vlp.NODE_LIST] = s:VimlLint.compile_list
let s:VimlLint.compile_funcs[s:vlp.NODE_DICT] = s:VimlLint.compile_dict
let s:VimlLint.compile_funcs[s:vlp.NODE_OPTION] = s:VimlLint.compile_option
let s:VimlLint.compile_funcs[s:vlp.NODE_IDENTIFIER] = s:VimlLint.compile_identifier
let s:VimlLint.compile_funcs[s:vlp.NODE_CURLYNAME] = s:VimlLint.compile_curlyname
let s:VimlLint.compile_funcs[s:vlp.NODE_ENV] = s:VimlLint.compile_env
let s:VimlLint.compile_funcs[s:vlp.NODE_REG] = s:VimlLint.compile_reg

let s:VimlLint.excmd_abbrev = {}
let s:VimlLint.excmd_abbrev[s:vlp.NODE_IF] = s:VimlLint.abbrev_if
let s:VimlLint.excmd_abbrev[s:vlp.NODE_FOR] = s:VimlLint.abbrev_for
let s:VimlLint.excmd_abbrev[s:vlp.NODE_WHILE] = s:VimlLint.abbrev_while
let s:VimlLint.excmd_abbrev[s:vlp.NODE_TRY] = s:VimlLint.abbrev_try
let s:VimlLint.excmd_abbrev[s:vlp.NODE_FUNCTION] = s:VimlLint.abbrev_func

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0 foldmethod=marker commentstring=\ "\ %s:
