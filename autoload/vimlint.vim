scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" 最低限やりたいこと {{{
" - let つけずに変数代入
" - call つけずに関数呼び出し
" - built-in 関数関連の引数チェック
" - scriptencoding 有無
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

call extend(s:, vimlparser#import())

let s:VimlLint = {}

let s:default_param = {} " {{{
let s:default_param.unused_argument = 1
let s:default_param.recursive = 1
let s:default_param.quiet = 0

let s:default_param_output = {
\   'append' : 0,
\   'filename' : ''}
" }}}

function s:VimlLint.new(param) " {{{
  let obj = copy(self)
  let obj.indent = ['']
  let obj.lines = []
  let obj.env = s:env({}, "")

  let obj.param = a:param
  let obj.error = []
  return obj
endfunction " }}}

" for debug " {{{
function! s:node2str(node) " {{{
  let a = {}
  let a[1] = 'TOPLEVEL'
  let a[2] = 'COMMENT'
  let a[3] = 'EXCMD'
  let a[4] = 'FUNCTION'
  let a[5] = 'ENDFUNCTION'
  let a[6] = 'DELFUNCTION'
  let a[7] = 'RETURN'
  let a[8] = 'EXCALL'
  let a[9] = 'LET'
  let a[10] = 'UNLET'
  let a[11] = 'LOCKVAR'
  let a[12] = 'UNLOCKVAR'
  let a[13] = 'IF'
  let a[14] = 'ELSEIF'
  let a[15] = 'ELSE'
  let a[16] = 'ENDIF'
  let a[17] = 'WHILE'
  let a[18] = 'ENDWHILE'
  let a[19] = 'FOR'
  let a[20] = 'ENDFOR'
  let a[21] = 'CONTINUE'
  let a[22] = 'BREAK'
  let a[23] = 'TRY'
  let a[24] = 'CATCH'
  let a[25] = 'FINALLY'
  let a[26] = 'ENDTRY'
  let a[27] = 'THROW'
  let a[28] = 'ECHO'
  let a[29] = 'ECHON'
  let a[30] = 'ECHOHL'
  let a[31] = 'ECHOMSG'
  let a[32] = 'ECHOERR'
  let a[33] = 'EXECUTE'
  let a[34] = 'TERNARY'
  let a[35] = 'OR'
  let a[36] = 'AND'
  let a[37] = 'EQUAL'
  let a[38] = 'EQUALCI'
  let a[39] = 'EQUALCS'
  let a[40] = 'NEQUAL'
  let a[41] = 'NEQUALCI'
  let a[42] = 'NEQUALCS'
  let a[43] = 'GREATER'
  let a[44] = 'GREATERCI'
  let a[45] = 'GREATERCS'
  let a[46] = 'GEQUAL'
  let a[47] = 'GEQUALCI'
  let a[48] = 'GEQUALCS'
  let a[49] = 'SMALLER'
  let a[50] = 'SMALLERCI'
  let a[51] = 'SMALLERCS'
  let a[52] = 'SEQUAL'
  let a[53] = 'SEQUALCI'
  let a[54] = 'SEQUALCS'
  let a[55] = 'MATCH'
  let a[56] = 'MATCHCI'
  let a[57] = 'MATCHCS'
  let a[58] = 'NOMATCH'
  let a[59] = 'NOMATCHCI'
  let a[60] = 'NOMATCHCS'
  let a[61] = 'IS'
  let a[62] = 'ISCI'
  let a[63] = 'ISCS'
  let a[64] = 'ISNOT'
  let a[65] = 'ISNOTCI'
  let a[66] = 'ISNOTCS'
  let a[67] = 'ADD'
  let a[68] = 'SUBTRACT'
  let a[69] = 'CONCAT'
  let a[70] = 'MULTIPLY'
  let a[71] = 'DIVIDE'
  let a[72] = 'REMAINDER'
  let a[73] = 'NOT'
  let a[74] = 'MINUS'
  let a[75] = 'PLUS'
  let a[76] = 'SUBSCRIPT'
  let a[77] = 'SLICE'
  let a[78] = 'CALL'
  let a[79] = 'DOT'
  let a[80] = 'NUMBER'
  let a[81] = 'STRING'
  let a[82] = 'LIST'
  let a[83] = 'DICT'
  let a[85] = 'OPTION'
  let a[86] = 'IDENTIFIER'
  let a[87] = 'CURLYNAME'
  let a[88] = 'ENV'
  let a[89] = 'REG'
  if type(a:node) == type({}) &&
  \  has_key(a:node, 'type') && has_key(a, a:node.type)
    return a[a:node.type]
  else
    return "unknown"
  endif
endfunction " }}}

function! s:tostring_varstack_n(v)
  let v = a:v
  let s = ""
  let s .= "type=" . v.type[0:2]
  let s .= ",ref=" . v.v.ref
  let s .= ",sub=" . v.v.subs
  let s .= ",stt=" . v.v.stat
  if has_key(v, "var")
    let s .= ",var=" . v.var
  elseif has_key(v, "rt_from")
    let s .= ",rm=" . v.rt_from . ".." .  v.rt_to
  else
    let s .= ",var="
  endif
  return s
endfunction

function! s:decho(str)
  if g:vimlint#debug > 1
    echo a:str
  endif
endfunction

" }}}

function! s:env(outer, funcname) " {{{
  let env = {}
  let env.outer = a:outer
  let env.function = a:funcname
  let env.var = {}
  let env.varstack = []
  let env.ret = 0
  let env.loopb = 0
  if has_key(a:outer, 'global')
    let env.global = a:outer.global
  else
    let env.global = env
    let env.loop = 0
    let env.fins = 0
  endif
  return env
endfunction " }}}

function! s:output_echo(filename, pos, eid, mes, obj) " {{{
  echo a:filename . ":" . a:pos.lnum . ":" . a:pos.col . ":" . a:eid . ': ' . a:mes
endfunction " }}}

function! s:output_file(filename, pos, eid, mes, obj) " {{{
  let a:obj.error += [a:filename . ":" . a:pos.lnum . ":" . a:pos.col . ":" . a:eid . ': ' . a:mes]
endfunction " }}}

function! s:output_list(filename, pos, eid, mes, obj) " {{{
  let a:obj.error += [[a:filename, a:pos.lnum, a:pos.col, a:eid, a:mes]]
endfunction " }}}

function! s:VimlLint.error_mes(node, eid, mes, print) " {{{
"  echo a:node
  if a:print
    let filename = get(self, 'filename', '...')
    let pos = vimlint#util#get_pos(a:node)
    call self.param.outfunc(filename, pos, a:eid, a:mes, self)
  endif
endfunction " }}}

" 変数参照 s:exists_var(env, node) {{{
" @param var string
" @param node dict: return value of compile
"  return {'type' : 'id', 'val' : name, 'node' : a:node}
function! s:exists_var(self, env, node)
  let var = a:node.value
  if var =~# '#'
    " チェックできない
    return 1
  endif

  if var !~# '^[gbwtslva]:'
    if a:env.global == a:env
      let var = 'g:' . var
    else
      let var = 'l:' . var
    endif
  endif

  if var =~# '^[gbwt]:'
    " check できない
    " 型くらいは保存してみる?
    return 1
  elseif var =~# '^[s]:'
    " 存在していることにして先にすすむ.
    " どこで定義されるかわからない
    call s:append_var_(a:env.global, var, a:node, 0, -1)
    return 1
  elseif var =~# '^v:'
    " @TODO :help v:
    " @TODO map 内などか?
    return 1
  else
    " ローカル変数
    let env = a:env
    while has_key(env, 'var')
      if has_key(env.var, var)
        " カウンタをアップデード
        let stat = env.var[var].stat
        call s:append_var_(env, var, a:node, 0, -1)

        if stat == 0
          return 1
        endif

        " 警告
        call a:self.error_mes(a:node, 'EVL104', 'variable may not be initialized on some execution path: `' . var . '`', 1)
        return 0
      endif
      let env = env.outer
    endwhile

    " 存在しなかった
    call a:self.error_mes(a:node, 'EVL101', 'undefined variable `' . var . '`', 1)
    return 0
  endif
endfunction " }}}

function! s:push_varstack(env, dict) " {{{

  let a:env.varstack += [a:dict]

  if !has_key(a:dict, "type") || type(a:dict.type) != type("")
    throw "varstack() invalid type: " . string(a:dict)
  endif
  if !has_key(a:dict, "v") || type(a:dict.v) != type({}) ||
  \ !has_key(a:dict.v, "ref") || !has_key(a:dict.v, "subs") ||
  \ !has_key(a:dict.v, "stat")
  \ || type(a:dict.v.ref) != type(1)
  \ || type(a:dict.v.subs) != type(1)
    throw "varstack() invalid v: " . string(a:dict)
  endif

endfunction " }}}

function! s:append_var_(env, var, node, val, cnt) " {{{

"  echo "append_var: var=" . a:var . ", cnt=" . a:cnt
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
function! s:VimlLint.append_var(env, var, val, pos)
  if type(a:var) != type({})
    " @debug
    echo "in append_var: invalid input: type=" . type(a:var) . ",pos=" . a:pos
    echo a:var
    throw "stop"
  endif
  let ret = {}

  if a:var.type == s:NODE_IDENTIFIER
    let node = a:var
    let v = a:var.value
    if v =~# "^[0-9]*$"
      echo "in append_var: invalid input: type=" . type(a:var) . ",pos=" . a:pos
      echo a:var
      throw "stop"
    endif
    if a:pos == 'a:'
      " 関数引数
      if v != '...'
        let ret = s:append_var_(a:env, 'a:' . v, node, a:val, 1)
      endif
      return ret
    endif

    " 接頭子は必ずつける.
    if v !~# '^[gbwtslv]:' && v !~# '#'
      if a:env.global == a:env
        let v = 'g:' . v
      else
        let v = 'l:' . v
      endif
    endif
    if v =~# '^[sgbwt]:'
      let ret = s:append_var_(a:env.global, v, node, a:val, 1)
    elseif v !~# '#'
      let ret = s:append_var_(a:env, v, node, a:val, 1)
    endif
  elseif a:var.type == s:NODE_REG
    " do nothing
    return ret
  elseif a:var.type == s:NODE_SUBSCRIPT
  elseif a:var.type == s:NODE_DOT
    " let f.f = xxxx, let f["a"] = xxxx
  elseif a:var.type == s:NODE_OPTION
    " do nothing
  elseif a:var.type == s:NODE_CURLYNAME
    " ???
  elseif a:var.type == s:NODE_ENV
    " $xxxx
  else
    " @TODO
    call self.error_mes(a:var, 'EVL901', 'unknown type `' . a:var.type . '`', 1)
  endif
  return ret
endfunction " }}}

function! s:delete_var(self, env, var, chk) " {{{
  if a:var.type == s:NODE_IDENTIFIER
    let name = a:var.value
    if name !~# '^[gbwtslv]:' && name !~# '#'
      if a:env.global == a:env
        let name = 'g:' . name
      else
        let name = 'l:' . name
      endif
    endif

    if has_key(a:env.var, name)
      let e = a:env
      let v = e.var[name]
      if a:chk == 1 && v.ref == 1
        call a:self.error_mes(v.node, 'EVL102', 'unused variable `' . name . '`', 1)
      endif
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

function! s:reset_env_cntl(env) " {{{
  let a:env.ret = 0
  let a:env.loopb = 0
endfunction " }}}

function! s:gen_pos_cntl(env, p) " {{{
  return [a:p, len(a:env.varstack), a:env.ret, a:env.loopb]
endfunction " }}}

function! s:restore_varstack(env, pos, pp) " {{{
  " @param pp は debug 用
  call s:simpl_varstack(a:env, a:pos, len(a:env.varstack) - 1)
  let i = len(a:env.varstack)
  call s:decho("restore: " . a:pp . ": " . a:pos)
  while i > a:pos
    let i = i - 1
    let v = a:env.varstack[i]
    call s:decho("restore[" . a:pp . "] " . i . "/" . a:pos . "/" . (len(a:env.varstack)-1) . " : " . s:tostring_varstack_n(v))
    if v.type == 'delete'
      let v.env.var[v.var] = v.v
    elseif v.type == 'append'
      " break されたりするときの restore では
      " let されているとは限らない
      " @TODO
      if has_key(v.env.var, v.var)
        unlet v.env.var[v.var]
      endif
    elseif v.type == 'update'
      let v.env.var[v.var].stat = v.stat
    elseif v.type != 'nop'
      throw "system error"
    endif
  endwhile
endfunction " }}}

function! s:simpl_varstack(env, pos, pose) " {{{
  let d = {}
  let nop = {'type' : 'nop', 'v' : {'ref' : 0, 'subs' : 0, 'stat' : 0}}

  call s:decho("simpl_varstack: " . a:pos . ".." . (len(a:env.varstack)-1))
  for i in range(a:pos, a:pose)
    let v = a:env.varstack[i]
    if v.type == 'nop'
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

function! s:reconstruct_varstack_rm(self, env, pos, nop) " {{{
  " remake
  for p in a:pos
    for j in range(p[0], p[1] - 1)
      let v = a:env.varstack[j]
      call s:decho("v[" . j . "]=" . v.type)
      if v.type == 'nop' && has_key(v, 'rt_from')
        " v.zz is a return value of reconstruct_varstack_rt
        " @@memo return [vardict, N, N_lp]
        let tail = len(a:env.varstack)
        call s:reconstruct_varstack_chk(a:self, a:env, v.zz, 1)
        let vs = a:env.varstack[tail :]
        call s:decho("nop-:" . v.rt_from . ".." . v.rt_to . ",tail=" . tail . ",vs=" . len(vs))
        for ui in range(len(vs))
          call remove(a:env.varstack, -1)
        endfor

        let ui = v.rt_from

        " @TODO 参照情報をコピー. かなり強引.
        let vref = {}
        for ui in range(v.rt_from, v.rt_to - 1)
          let vp = a:env.varstack[ui]
          if vp.type == "append"
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
          if ui + ti >= v.rt_to && a:env.varstack[ui + ti].type != 'nop'
            throw "stop"
          endif
          let a:env.varstack[ui + ti] = vs[ti]
          call s:decho("recon2: varstack[" . (ui+ti) . "]=vs[" . ti . "]=" . s:tostring_varstack_n(vs[ti]))
          if vs[ti].type == "append" && has_key(vref, vs[ti].var)
            let vs[ti].v.ref += vref[vs[ti].var]
          endif
        endfor
        let ui = ui + ti
        while ui < v.rt_to
          let a:env.varstack[ui] = a:nop
"          echo "recon2: varstack[" . (ui) . "]=nop"
          let ui = ui + 1
        endwhile
      endif
    endfor
    call s:simpl_varstack(a:env, p[0], p[1] - 1)
  endfor

endfunction " }}}

function! s:reconstruct_varstack_rt(self, env, pos, brk_cont, nop) " {{{
  " すべてのルートをチェックして,
  " 変数の代入、参照状態を構築する
  let vardict = {} " 変数情報を詰め込む
  let nop = a:nop

  let N = 0 " return しないルート数
  let N_lp = 0 " break/continue されたルート数

  for p in a:pos
    call s:decho("reconstruct_rt: " . string(p) . "/" . len(a:pos))
    if p[2] " return した.
      " イベントをなかったことにする
      for j in range(p[0], p[1] - 1)
        let v = a:env.varstack[j]
        if v.type == 'append' && v.v.ref == 0 && a:env.global.fins == 0
          " 変数を追加したが参照していない
          " かつ,  finally 句がない場合
          call a:self.error_mes(v.node, 'EVL102', 'unused variable2 `' . v.var. '`', 1)
        endif
        let a:env.varstack[j] = nop
      endfor
      continue
    endif
    let N += 1
"echo "p=" . string(p) . ", brk=" . a:brk_cont
    if p[3] && !a:brk_cont
      let N_lp += 1
      continue
    endif
    let vi = {}
    for j in range(p[0], p[1] - 1)
      let v = a:env.varstack[j]
      call s:decho("reconstruct" . j . "/" . (p[1]-1) . ":    " . s:tostring_varstack_n(v) . ",pos=" . string(p))
      if v.type == 'nop'
        continue
      endif
      if has_key(vi, v.var)
        " if 文内で定義したものを削除した など
        " simplify によりありえない
        echo "============ ERR ============="
"        echo v
"        echo vi[v.var]
        throw "err: simpl_varstack()"
      endif

      if v.type == 'delete'
        " if 文前に定義したものを削除した
        let vi[v.var] = [v, 0, 1, 0, 0]
      elseif v.type == 'append' || v.type == 'update'
        let vi[v.var] = [v, 1, 0, 0, 0]
      elseif v.type != 'nop'
        call self.error_mes(v.v, 'EVL901', 'unknown type `' . a:var.type . '`', 1)
      endif
    endfor

    " 情報をマージ
    for k in keys(vi)
      call s:decho("_rt(): vi[" . k . "]=" . string(vi[k][1:]) . ",ref=" . vi[k][0].v.ref)
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

  return [vardict, N, N_lp]
endfunction " }}}

function! s:reconstruct_varstack_chk(self, env, rtret, brk_cont) "{{{
  " reconstruct_varstack_rt() で構築した情報をもとに,
  let vardict = a:rtret[0]
  let N = a:rtret[1]
  let N_lp = a:rtret[2]

  for k in keys(vardict)
    let z = vardict[k]
    if z[2]  + N_lp == N
      " すべてのルートで delete
      call s:delete_var(a:self, a:env, z[0].node, -1)
    else
      try
        " あるルートでは delete されなかった.
        " あるルートで append された
        " すべてのルートで append された
        let z[0].v.v = a:self.append_var(z[0].env, z[0].node, z[0].var, 'reconstruct')
        " ref 情報を追加しないと.
        if z[3] > 0
          call s:exists_var(a:self, a:self.env, z[0].node)
        endif

      catch
        echo v:exception
        echo v:errmsg
        echo v:throwpoint
        throw "stop"
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

function! s:reconstruct_varstack(self, env, pos, is_loop) " {{{
  " a:pos は s:gen_pos_cntl() により構築される
  " すべてのルートをみて変数定義まわりの情報を再構築する
  " test/for7.vim とか.

  let nop = {'type' : 'nop', 'v' : {'ref' : 0, 'subs' : 0, 'stat' : 0}}
"  echo "reconstruct: " . string(a:pos)

  if a:is_loop
    " varstack を modify する.

    call s:reconstruct_varstack_rm(a:self, a:env, a:pos, nop)
    let rtret = s:reconstruct_varstack_rt(a:self, a:env, a:pos, 1, nop)
  else
    let rtret = s:reconstruct_varstack_rt(a:self, a:env, a:pos, 0, nop)
  endif

  let vardict = rtret[0]
  let N = rtret[1]
  let N_lp = rtret[2]

  if N == 0
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

  call s:decho("construct rvrt2: range=" . v.rt_from . ".." . v.rt_to)
  let rvrt2 = s:reconstruct_varstack_rt(a:self, a:env, a:pos, 1, nop)
  call s:decho("vard=" . len(vardict) . ", var2=" . len(rvrt2[0]))
  " @TODO 参照情報をコピーする.

  if len(vardict) <= len(rvrt2[0]) - 1
    for i in range(len(vardict), len(rvrt2[0]) - 1)
      call s:push_varstack(a:env, nop)
    endfor
  endif
  let v.zz = rvrt2

  call s:push_varstack(a:env, v)
endfunction " }}}

function! s:reconstruct_varstack_st(self, env, p) " {{{
  " try 句の reconstrutt. どこで例外が発生するかわからない状態
  " @param p(list) reconstruct_varstack() の pos(listlist) と同じではない
  for j in range(a:p, len(a:env.varstack) - 1)
    let v = a:env.varstack[j]
    if v.type == 'append'
      let v.stat = 1
    endif
  endfor

endfunction " }}}

function! s:echonode(node, refchk) " {{{
  echo "compile. " . s:node2str(a:node) . "(" . a:node.type . "), val=" .
    \ (has_key(a:node, "value") ?
    \ (type(a:node.value) ==# type("") ? a:node.value : "@@" . type(a:node.value)) : "%%") .
    \  ", ref=" . a:refchk
endfunction " }}}

function s:VimlLint.compile(node, refchk) " {{{
  if type(a:node) ==# type({}) && has_key(a:node, 'type')
    if a:node.type != 2 && g:vimlint#debug > 2
      call s:echonode(a:node, a:refchk)
    endif
"  else
"    echo "node=" . type(a:node)
"    echo a:node
  endif

  try
    let a:node.sg_type_str = s:node2str(a:node)
  catch
    echo v:exception
    echo a:node
    throw "stop"
  endtry

  if a:node.type == s:NODE_TOPLEVEL " {{{
    return self.compile_toplevel(a:node, a:refchk)
  elseif a:node.type == s:NODE_COMMENT
    return self.compile_comment(a:node, a:refchk)
  elseif a:node.type == s:NODE_EXCMD
    return self.compile_excmd(a:node, a:refchk)
  elseif a:node.type == s:NODE_FUNCTION
    return self.compile_function(a:node, a:refchk)
  elseif a:node.type == s:NODE_DELFUNCTION
    return self.compile_delfunction(a:node, a:refchk)
  elseif a:node.type == s:NODE_RETURN
    return self.compile_return(a:node, a:refchk)
  elseif a:node.type == s:NODE_EXCALL
    return self.compile_excall(a:node, a:refchk)
  elseif a:node.type == s:NODE_LET
    return self.compile_let(a:node, a:refchk)
  elseif a:node.type == s:NODE_UNLET
    return self.compile_unlet(a:node, a:refchk)
  elseif a:node.type == s:NODE_LOCKVAR
    return self.compile_lockvar(a:node, a:refchk)
  elseif a:node.type == s:NODE_UNLOCKVAR
    return self.compile_unlockvar(a:node, a:refchk)
  elseif a:node.type == s:NODE_IF
    return self.compile_if(a:node, a:refchk)
  elseif a:node.type == s:NODE_WHILE
    return self.compile_while(a:node, a:refchk)
  elseif a:node.type == s:NODE_FOR
    return self.compile_for(a:node, a:refchk)
  elseif a:node.type == s:NODE_CONTINUE
    return self.compile_continue(a:node, a:refchk)
  elseif a:node.type == s:NODE_BREAK
    return self.compile_break(a:node, a:refchk)
  elseif a:node.type == s:NODE_TRY
    return self.compile_try(a:node, a:refchk)
  elseif a:node.type == s:NODE_THROW
    return self.compile_throw(a:node, a:refchk)
  elseif a:node.type == s:NODE_ECHO
    return self.compile_echo(a:node, a:refchk)
  elseif a:node.type == s:NODE_ECHON
    return self.compile_echon(a:node, a:refchk)
  elseif a:node.type == s:NODE_ECHOHL
    return self.compile_echohl(a:node, a:refchk)
  elseif a:node.type == s:NODE_ECHOMSG
    return self.compile_echomsg(a:node, a:refchk)
  elseif a:node.type == s:NODE_ECHOERR
    return self.compile_echoerr(a:node, a:refchk)
  elseif a:node.type == s:NODE_EXECUTE
    return self.compile_execute(a:node, a:refchk)
  elseif a:node.type == s:NODE_TERNARY
    return self.compile_ternary(a:node, a:refchk)
  elseif a:node.type == s:NODE_OR
    return self.compile_or(a:node)
  elseif a:node.type == s:NODE_AND
    return self.compile_and(a:node)
  elseif a:node.type == s:NODE_EQUAL
    return self.compile_equal(a:node)
  elseif a:node.type == s:NODE_EQUALCI
    return self.compile_equalci(a:node)
  elseif a:node.type == s:NODE_EQUALCS
    return self.compile_equalcs(a:node)
  elseif a:node.type == s:NODE_NEQUAL
    return self.compile_nequal(a:node)
  elseif a:node.type == s:NODE_NEQUALCI
    return self.compile_nequalci(a:node)
  elseif a:node.type == s:NODE_NEQUALCS
    return self.compile_nequalcs(a:node)
  elseif a:node.type == s:NODE_GREATER
    return self.compile_greater(a:node)
  elseif a:node.type == s:NODE_GREATERCI
    return self.compile_greaterci(a:node)
  elseif a:node.type == s:NODE_GREATERCS
    return self.compile_greatercs(a:node)
  elseif a:node.type == s:NODE_GEQUAL
    return self.compile_gequal(a:node)
  elseif a:node.type == s:NODE_GEQUALCI
    return self.compile_gequalci(a:node)
  elseif a:node.type == s:NODE_GEQUALCS
    return self.compile_gequalcs(a:node)
  elseif a:node.type == s:NODE_SMALLER
    return self.compile_smaller(a:node)
  elseif a:node.type == s:NODE_SMALLERCI
    return self.compile_smallerci(a:node)
  elseif a:node.type == s:NODE_SMALLERCS
    return self.compile_smallercs(a:node)
  elseif a:node.type == s:NODE_SEQUAL
    return self.compile_sequal(a:node)
  elseif a:node.type == s:NODE_SEQUALCI
    return self.compile_sequalci(a:node)
  elseif a:node.type == s:NODE_SEQUALCS
    return self.compile_sequalcs(a:node)
  elseif a:node.type == s:NODE_MATCH
    return self.compile_match(a:node)
  elseif a:node.type == s:NODE_MATCHCI
    return self.compile_matchci(a:node)
  elseif a:node.type == s:NODE_MATCHCS
    return self.compile_matchcs(a:node)
  elseif a:node.type == s:NODE_NOMATCH
    return self.compile_nomatch(a:node)
  elseif a:node.type == s:NODE_NOMATCHCI
    return self.compile_nomatchci(a:node)
  elseif a:node.type == s:NODE_NOMATCHCS
    return self.compile_nomatchcs(a:node)
  elseif a:node.type == s:NODE_IS
    return self.compile_is(a:node)
  elseif a:node.type == s:NODE_ISCI
    return self.compile_isci(a:node)
  elseif a:node.type == s:NODE_ISCS
    return self.compile_iscs(a:node)
  elseif a:node.type == s:NODE_ISNOT
    return self.compile_isnot(a:node)
  elseif a:node.type == s:NODE_ISNOTCI
    return self.compile_isnotci(a:node)
  elseif a:node.type == s:NODE_ISNOTCS
    return self.compile_isnotcs(a:node)
  elseif a:node.type == s:NODE_ADD
    return self.compile_add(a:node)
  elseif a:node.type == s:NODE_SUBTRACT
    return self.compile_subtract(a:node)
  elseif a:node.type == s:NODE_CONCAT
    return self.compile_concat(a:node)
  elseif a:node.type == s:NODE_MULTIPLY
    return self.compile_multiply(a:node)
  elseif a:node.type == s:NODE_DIVIDE
    return self.compile_divide(a:node)
  elseif a:node.type == s:NODE_REMAINDER
    return self.compile_remainder(a:node)
  elseif a:node.type == s:NODE_NOT
    return self.compile_not(a:node)
  elseif a:node.type == s:NODE_PLUS
    return self.compile_plus(a:node)
  elseif a:node.type == s:NODE_MINUS
    return self.compile_minus(a:node)
  elseif a:node.type == s:NODE_SUBSCRIPT
    return self.compile_subscript(a:node)
  elseif a:node.type == s:NODE_SLICE
    return self.compile_slice(a:node, a:refchk)
  elseif a:node.type == s:NODE_DOT
    return self.compile_dot(a:node, a:refchk)
  elseif a:node.type == s:NODE_CALL
    return self.compile_call(a:node, a:refchk)
  elseif a:node.type == s:NODE_NUMBER
    return self.compile_number(a:node)
  elseif a:node.type == s:NODE_STRING
    return self.compile_string(a:node)
  elseif a:node.type == s:NODE_LIST
    return self.compile_list(a:node, a:refchk)
  elseif a:node.type == s:NODE_DICT
    return self.compile_dict(a:node, a:refchk)
  elseif a:node.type == s:NODE_OPTION
    return self.compile_option(a:node)
  elseif a:node.type == s:NODE_IDENTIFIER
    return self.compile_identifier(a:node, a:refchk)
  elseif a:node.type == s:NODE_CURLYNAME
    return self.compile_curlyname(a:node, a:refchk)
  elseif a:node.type == s:NODE_ENV
    return self.compile_env(a:node, a:refchk)
  elseif a:node.type == s:NODE_REG
    return self.compile_reg(a:node)
  else
    throw self.err('Compiler: unknown node: %s', string(a:node))
  endif " }}}
endfunction " }}}

function s:VimlLint.compile_body(body, refchk) " {{{
  for node in a:body
    if self.env.ret + self.env.loopb > 0 && node.type != s:NODE_COMMENT
      call self.error_mes(node, 'EVL201', "unreachable code: " .
      \ (self.env.ret > 0 ? "return/throw" : "continue/break"), 1)
      break
    endif
    call self.compile(node, a:refchk)
  endfor
endfunction " }}}

function s:VimlLint.compile_toplevel(node, refchk) " {{{
  call self.compile_body(a:node.body, a:refchk)
  return self.lines
endfunction " }}}

function s:VimlLint.compile_comment(node, refchk) " {{{
endfunction " }}}

function s:VimlLint.compile_excmd(node, refchk) " {{{
" @TODO
" e.g. set cpo&vim
" e.g. a = 3   (let 漏れ)

  "  lcd `=cwd`
  let s = matchstr(a:node.str, "`=.[^`]*`")
  if '' != s
    call self.parse_string(s[2:-2], a:node, 'ExCommand')
    return
  endif

  "  redir => res, redir =>> res
  let s = matchstr(a:node.str, '\s*redi[r]\?\s\+=>[>]\?\s*\zs.*\ze\s*')
  if s != '' && s != 'END'
    let a:node.type = s:NODE_IDENTIFIER
    let a:node.value = s
    call self.append_var(self.env, a:node, s:NIL, 'redir')
    return
  endif

  let s = substitute(a:node.str, '\s', '', 'g')
  " call つけて parse しなおしたほうが良いだろうけど.
  if a:node.str !~# '^\s*\w\+\s\+\w' &&
  \  s =~# '^\([gbwtsl]:\)\?[#A-Za-z0-9_]\+\(\.\w\+\|\[.*\]\)*(.*)$'
    call self.error_mes(a:node, 'EVL202', 'missing call `' . s . '`', 1)
  endif

endfunction

function s:VimlLint.compile_function(node, refchk)
  " @TODO left が dot/subs だった場合にのみ self は予約語とする #5
  let left = self.compile(a:node.left, 0) " name of function
  let rlist = map(a:node.rlist, 'self.compile(v:val, 0)')  " list of argument string

  let self.env = s:env(self.env, left)
  if a:node.attr.range
    call s:append_var_(self.env, "a:firstline", a:node, a:node, 1)
    call s:append_var_(self.env, "a:lastline", a:node, a:node, 1)
  endif
  for v in rlist
    " E853 if Duplicate argument
    call self.append_var(self.env, v, s:NIL, "a:")
    unlet v
  endfor
  call self.compile_body(a:node.body, 1)

  " 未使用変数は?
  for v in keys(self.env.var)
    if self.env.var[v].ref == 0
      " a: は例外とする, オプションが必要 @TODO
"      echo self.env.var[v]
      if v =~# '^a:'
        call self.error_mes(self.env.var[v].node, 'EVL103', 'unused argument `' . v . '`', self.param['unused_argument'])
      else
        call self.error_mes(self.env.var[v].node, 'EVL102', 'unused variable `' . v . '`', 1)
      endif
    endif
  endfor

  let self.env = self.env.outer
endfunction " }}}

function s:VimlLint.compile_delfunction(node, rechk) " {{{
  " @TODO function は定義済か?
endfunction " }}}

function s:VimlLint.compile_return(node, refchk) " {{{

  if self.env == self.env.global
    call self.error_mes(a:node, 'E133', ':return not inside a function', 1)
  elseif a:node.left is s:NIL
    let self.env.ret = 1
  else
    call self.compile(a:node.left, 1)
    let self.env.ret = 1
  endif
endfunction " }}}

function s:VimlLint.compile_excall(node, refchk) " {{{
  return self.compile(a:node.left, a:refchk)
endfunction " }}}

function s:VimlLint.compile_let(node, refchk) " {{{
  if type(a:node.right) != type({})
    echo "compile_let. right is invalid"
    echo a:node
  endif
  let right = self.compile(a:node.right, 1)

  if a:node.left isnot s:NIL
    let left = self.compile(a:node.left, 0)
    if s:readonly_var(left)
      call self.error_mes(left, 'E46', 'Cannot change read-only variable ' . left.value, 1)
    else
      call self.append_var(self.env, left, right, "let1")
    endif
  else
    let list = map(a:node.list, 'self.compile(v:val, 0)')
    call map(list, 'self.append_var(self.env, v:val, right, "letn")')
    if a:node.rest isnot s:NIL
      let v = self.compile(a:node.rest, 0)
      if s:readonly_var(v)
        call self.error_mes(left, 'E46', 'Cannot change read-only variable ' . left.value, 1)
      else
        call self.append_var(self.env, v, right, "letr")
      endif
    endif
  endif
endfunction " }}}

function s:VimlLint.compile_unlet(node, refchk) "{{{
  " @TODO unlet! の場合には存在チェック不要
  let f = a:node.ea.forceit ? 0 : 1
  let list = map(a:node.list, 'self.compile(v:val, ' . f . ')')
  for v in list
    " unlet
    call s:delete_var(self, self.env, v, f)
  endfor
endfunction "}}}

function s:VimlLint.compile_lockvar(node, refchk) "{{{
  for var in a:node.list
    if var.type != s:NODE_IDENTIFIER
"      call self.error_mes(a:node, "Ex#, 'lockvar: internal variable is required: ' . var, 1)
    else
      call s:exists_var(self, self.env, var)
"      call self.error_mes(a:node, "Ex#, 'undefined variable: ' . var, 1)
    endif
  endfor
endfunction "}}}

function s:VimlLint.compile_unlockvar(node, refchk) "{{{
  for var in a:node.list
    if var.type != s:NODE_IDENTIFIER
"      call self.error_mes(a:node, 'lockvar: internal variable is required: ' . var, 1)
    else
      call s:exists_var(self, self.env, var)
"      call self.error_mes(a:node, 'undefined variable: ' . var, 1)
    endif
  endfor
endfunction "}}}

function s:VimlLint.compile_if(node, refchk) "{{{
"  call s:VimlLint.error_mes(a:node, "compile_if")
  let cond = self.compile(a:node.cond, 2) " if ()

  if cond.type == s:NODE_NUMBER
      call self.error_mes(a:node, 'EVL204', "constant in conditional context", 1)
  endif

  let p = len(self.env.varstack)
  call self.compile_body(a:node.body, a:refchk)

  call s:restore_varstack(self.env, p, "if1")

  let pos = [s:gen_pos_cntl(self.env, p)]
  call s:reset_env_cntl(self.env)

  for node in a:node.elseif
    call self.compile(node.cond, 2)
    let p = len(self.env.varstack)
    call self.compile_body(node.body, a:refchk)
    call s:restore_varstack(self.env, p, "if2")

    let pos += [s:gen_pos_cntl(self.env, p)]
    call s:reset_env_cntl(self.env)
  endfor

  let p = len(self.env.varstack)

  if a:node.else isnot s:NIL
    call self.compile_body(a:node.else.body, a:refchk)
    call s:restore_varstack(self.env, p, "if3")
  endif

  let pos += [s:gen_pos_cntl(self.env, p)]
  call s:reset_env_cntl(self.env)

  " reconstruct
  " let して return した、は let していないにする
  call s:decho("call reconstruct _ifs: " . string(a:node.pos))
  call s:reconstruct_varstack(self, self.env, pos, 0)
  call s:decho("call reconstruct _ife: " . string(a:node.pos))

endfunction "}}}

function s:VimlLint.compile_while(node, refchk) "{{{
  let cond = self.compile(a:node.cond, 1)

  if cond.type == s:NODE_NUMBER
    " while 0
    if str2nr(cond.value) == 0
      if len(a:node.body) > 0
        let node = a:node.body[0]
      else
        let node = a:node
      endif
      call self.error_mes(node, 'EVL201', "unreachable code: while", 1)
      return
    endif
  endif

  let self.env.global.loop += 1

  " while 文の中
  let p = len(self.env.varstack)
  call self.compile_body(a:node.body, a:refchk)

  if cond.type != s:NODE_NUMBER
    " 通常ルート
    call s:restore_varstack(self.env, p, "whl")
    let pos = [s:gen_pos_cntl(self.env, p)]
    call s:reset_env_cntl(self.env)


    " while にはいらなかった場合
    let p = len(self.env.varstack)
    let pos += [s:gen_pos_cntl(self.env, p)]
    call s:reset_env_cntl(self.env)

    call s:reconstruct_varstack(self, self.env, pos, 1)
  else
    " while 1
    " return/break/continue が必須.
    " throw があるから....
    let self.env.loopb = 0
  endif

  let self.env.global.loop -= 1

endfunction "}}}

function s:VimlLint.compile_for(node, refchk) "{{{
  " VAR が変数のリスト、または変数であることは, vimlparser がチェックしている
  " right がリストであることはチェックしていない.
  " for VAR in LIST
  "   BODy
  " endfor
  let right = self.compile(a:node.right, 1) " LIST
  if right.type == s:NODE_NUMBER ||
  \  right.type == s:NODE_DICT ||
  \  right.type == s:NODE_STRING
    call self.error_mes(right, 'E714', 'List required', 1)
    return
  endif

  if right.type == s:NODE_LIST
    if len(right.value) == 0
      if len(a:node.body) > 0
        let node = a:node.body[0]
      else
        let node = right
      endif
      call self.error_mes(node, 'EVL201', "unreachable code: for", 1)
      return
    endif
  endif

  if a:node.left isnot s:NIL " for {var} in {list}
    let left = self.compile(a:node.left, 0)
    call self.append_var(self.env, left, right, "for")
    " append
"    echo "compile for, left is"
"    echo left
  else
    " for [{var1},...] in {listlist}
    let list = map(a:node.list, 'self.compile(v:val, 0)')
    call map(list, 'self.append_var(self.env, v:val, right, "forn")')

    " append
    if a:node.rest isnot s:NIL
      let rest = self.compile(a:node.rest, 0)
      call self.append_var(self.env, rest, right, "forr")
    endif
  endif

  let self.env.global.loop += 1

  " for 文の中
  let p = len(self.env.varstack)
  call self.compile_body(a:node.body, 1)


  call s:restore_varstack(self.env, p, "for")
  let pos = [s:gen_pos_cntl(self.env, p)]
  call s:reset_env_cntl(self.env)
  if right.type != s:NODE_LIST
    " for にはいらなかった場合
    let p = len(self.env.varstack)
    let pos += [s:gen_pos_cntl(self.env, p)]
  endif
  call s:decho("call reconstruct _fors: " . string(a:node.pos))
  call s:reconstruct_varstack(self, self.env, pos, 1)
  call s:decho("call reconstruct _fore: " . string(a:node.pos))
  let self.env.global.loop -= 1
endfunction "}}}

function s:VimlLint.compile_continue(node, refchk) "{{{
  if self.env.global.loop <= 0
    " vimlparser....
    call self.error_mes(a:node, 'E586', ':continue without :while or :for: continue', 1)
  else
    let self.env.loopb = 1
  endif
endfunction "}}}

function s:VimlLint.compile_break(node, refchk) "{{{
  if self.env.global.loop <= 0
    call self.error_mes(a:node, 'E587', ':break without :while or :for: break', 1)
  else
    let self.env.loopb = 1
  endif
endfunction "}}}

function s:VimlLint.compile_try(node, refchk) "{{{

  let p = len(self.env.varstack)
  call self.compile_body(a:node.body, a:refchk)

  if a:node.finally isnot s:NIL
    let self.env.global.fins += 1
  endif

  let pos_try = s:gen_pos_cntl(self.env, p)

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

    if node.pattern isnot s:NIL
      call self.compile_body(node.body, a:refchk)
    else
      call self.compile_body(node.body, a:refchk)
    endif

    call s:restore_varstack(self.env, p, "cth")

    let pos += [s:gen_pos_cntl(self.env, p)]
    call s:reset_env_cntl(self.env)

  endfor

  " @TODO

  call s:reconstruct_varstack(self, self.env, pos, 0)

  " backup env
  let retc = self.env.ret
  let loopbc = self.env.loopb

  call s:reset_env_cntl(self.env)

  if a:node.finally isnot s:NIL
    let self.env.global.fins -= 1
    call self.compile_body(a:node.finally.body, a:refchk)
  endif

  let self.env.ret = (ret && retc)
  let self.env.loopb = (loopb && loopbc)

endfunction "}}}

function s:VimlLint.compile_throw(node, refchk) "{{{
  call self.compile(a:node.left, 1)
  " return みたいなものでしょう.
  let self.env.ret = 1
endfunction "}}}

function s:VimlLint.compile_echo(node, refchk) "{{{
  let list = map(a:node.list, 'self.compile(v:val, 1)')
endfunction "}}}

function s:VimlLint.compile_echon(node, refchk) "{{{
  let list = map(a:node.list, 'self.compile(v:val, 1)')
endfunction "}}}

function s:VimlLint.compile_echohl(node, refchk) "{{{
  " @TODO
endfunction "}}}

function s:VimlLint.compile_echomsg(node, refchk) "{{{
  let list = map(a:node.list, 'self.compile(v:val, 1)')
endfunction "}}}

function s:VimlLint.compile_echoerr(node, refchk) "{{{
  let list = map(a:node.list, 'self.compile(v:val, 1)')
endfunction "}}}

function s:VimlLint.compile_execute(node, refchk) "{{{
  let list = map(a:node.list, 'self.compile(v:val, 1)')
endfunction "}}}

" expr1: expr2 ? expr1 : expr1
function s:VimlLint.compile_ternary(node, refchk) "{{{
  let a:node.cond = self.compile(a:node.cond, 1)
  let a:node.left = self.compile(a:node.left, 1)
  let a:node.right = self.compile(a:node.right, 1)
  return a:node
endfunction "}}}

" op2 {{{
function s:VimlLint.compile_or(node)
  return self.compile_op2(a:node, 'or')
endfunction

function s:VimlLint.compile_and(node)
  return self.compile_op2(a:node, 'and')
endfunction

function s:VimlLint.compile_equal(node)
  return self.compile_op2(a:node, '==')
endfunction

function s:VimlLint.compile_equalci(node)
  return self.compile_op2(a:node, '==?')
endfunction

function s:VimlLint.compile_equalcs(node)
  return self.compile_op2(a:node, '==#')
endfunction

function s:VimlLint.compile_nequal(node)
  return self.compile_op2(a:node, '!=')
endfunction

function s:VimlLint.compile_nequalci(node)
  return self.compile_op2(a:node, '!=?')
endfunction

function s:VimlLint.compile_nequalcs(node)
  return self.compile_op2(a:node, '!=#')
endfunction

function s:VimlLint.compile_greater(node)
  return self.compile_op2(a:node, '>')
endfunction

function s:VimlLint.compile_greaterci(node)
  return self.compile_op2(a:node, '>?')
endfunction

function s:VimlLint.compile_greatercs(node)
  return self.compile_op2(a:node, '>#')
endfunction

function s:VimlLint.compile_gequal(node)
  return self.compile_op2(a:node, '>=')
endfunction

function s:VimlLint.compile_gequalci(node)
  return self.compile_op2(a:node, '>=?')
endfunction

function s:VimlLint.compile_gequalcs(node)
  return self.compile_op2(a:node, '>=#')
endfunction

function s:VimlLint.compile_smaller(node)
  return self.compile_op2(a:node, '<')
endfunction

function s:VimlLint.compile_smallerci(node)
  return self.compile_op2(a:node, '<?')
endfunction

function s:VimlLint.compile_smallercs(node)
  return self.compile_op2(a:node, '<#')
endfunction

function s:VimlLint.compile_sequal(node)
  return self.compile_op2(a:node, '<=')
endfunction

function s:VimlLint.compile_sequalci(node)
  return self.compile_op2(a:node, '<=?')
endfunction

function s:VimlLint.compile_sequalcs(node)
  return self.compile_op2(a:node, '<=#')
endfunction

function s:VimlLint.compile_match(node)
  return self.compile_op2(a:node, 'match')
endfunction

function s:VimlLint.compile_matchci(node)
  return self.compile_op2(a:node, 'matchci')
endfunction

function s:VimlLint.compile_matchcs(node)
  return self.compile_op2(a:node, 'matchcs')
endfunction

function s:VimlLint.compile_nomatch(node)
  return self.compile_op2(a:node, 'nomatch')
endfunction

function s:VimlLint.compile_nomatchci(node)
  return self.compile_op2(a:node, 'nomatchci')
endfunction

function s:VimlLint.compile_nomatchcs(node)
  return self.compile_op2(a:node, 'nomatchcs')
endfunction

function s:VimlLint.compile_is(node)
  return self.compile_op2(a:node, 'is')
endfunction

function s:VimlLint.compile_isci(node)
  return self.compile_op2(a:node, 'is?')
endfunction

function s:VimlLint.compile_iscs(node)
  return self.compile_op2(a:node, 'is#')
endfunction

function s:VimlLint.compile_isnot(node)
  return self.compile_op2(a:node, 'is not')
endfunction

function s:VimlLint.compile_isnotci(node)
  return self.compile_op2(a:node, 'isnot?')
endfunction

function s:VimlLint.compile_isnotcs(node)
  return self.compile_op2(a:node, 'isnot#')
endfunction

function s:VimlLint.compile_add(node)
  return self.compile_op2(a:node, '+')
endfunction

function s:VimlLint.compile_subtract(node)
  return self.compile_op2(a:node, '-')
endfunction

function s:VimlLint.compile_concat(node)
  return self.compile_op2(a:node, '+')
endfunction

function s:VimlLint.compile_multiply(node)
  return self.compile_op2(a:node, '*')
endfunction

function s:VimlLint.compile_divide(node)
  return self.compile_op2(a:node, '/')
endfunction

function s:VimlLint.compile_remainder(node)
  return self.compile_op2(a:node, '%')
endfunction
" }}}

" op1 {{{
function s:VimlLint.compile_not(node)
  return self.compile_op1(a:node, 'not ')
endfunction

function s:VimlLint.compile_plus(node)
  return self.compile_op1(a:node, '+')
endfunction

function s:VimlLint.compile_minus(node)
  return self.compile_op1(a:node, '-')
endfunction
" }}}

function! s:escape_string(str) "{{{
  if a:str[0] == "'"
      return substitute(a:str, "''", "'", 'g')
  endif

  return a:str
endfunction "}}}

function s:VimlLint.parse_string(str, node, cmd) "{{{
  try
    let p = s:VimLParser.new()
    let c = s:VimlLint.new(self.param)
    let c.env = self.env
    let r = s:StringReader.new('echo ' . a:str)
    call c.compile(p.parse(r), 1)
  catch
    call self.error_mes(a:node, 'EVL203', 'parse error in `' . a:cmd . '`', 1)
  endtry
endfunction "}}}

function s:VimlLint.compile_call(node, refchk) "{{{
  let rlist = map(a:node.rlist, 'self.compile(v:val, 1)')
  let left = self.compile(a:node.left, 0)
  if has_key(left, 'value') && type(left.value) == type("")
    let d = vimlint#builtin#get_func_inf(left.value)
    if d != {}
      if len(rlist) < d.min
        call self.error_mes(left, 'E119', 'Not enough arguments for function: ' . left.value, 1)
      elseif len(rlist) > d.max
        call self.error_mes(left, 'E118', 'Too many arguments for function: ' . left.value, 1)
      else
"        for i in range(len(rlist))
          " 型チェック
"        endfor
      endif
    endif

    " 例外で, map と filter と,
    " @TODO vital... はどうしよう
    " 引数誤りはチェック済, にする.
    if left.value == 'map' || left.value == 'filter'
      if len(rlist) == 2 && type(rlist[1]) == type({}) && has_key(rlist[1], 'value')
        if rlist[1].type == s:NODE_STRING
          let s = s:escape_string(rlist[1].value)
          call self.parse_string(s[1:-2], left, left.value)
        endif
      endif
    elseif left.value == 'eval'
      if len(rlist) == 1 && type(rlist[0]) == type({}) && has_key(rlist[0], 'value')
        if rlist[0].type == s:NODE_STRING
          let s = s:escape_string(rlist[0].value)
          call self.parse_string(s[1:-2], left, left.value)
        endif
      endif
    elseif left.value == 'substitute'
      if len(rlist) >= 3 && type(rlist[2]) == type({})
      \ && has_key(rlist[2], 'value') && rlist[2].value[1:] =~# '^\\='
        let s = s:escape_string(rlist[2].value)
        call self.parse_string(s[3:-2], left, left.value)
      endif
    endif
  endif

  let rlist = map(a:node.rlist, 'self.compile(v:val, 1)')
  let left = self.compile(a:node.left, 0)

  let a:node.rlist = rlist
  let a:node.left = left

  return a:node
"  return {'type' : 'call', 'l' : left, 'r' : rlist, 'node' : a:node}
endfunction "}}}

" subst slice
" :let l = mylist[:3]             " first four items
" :let l = mylist[4:4]            " List with one item
" :let l = mylist[:]              " shallow copy of a List
function s:VimlLint.compile_slice(node, refchk) " {{{
  for i in range(len(a:node.rlist))
    let r = a:node.rlist[i] is s:NIL ? s:NIL : self.compile(a:node.rlist[i], 1)
    let a:node.rlist[i] = r
    unlet r
  endfor
  let a:node.left = self.compile(a:node.left, 1)
  return a:node
"  return {'type' : 'slice', 'l' : left, 'r' : [r0,r1], 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_subscript(node) " {{{
  let a:node.left = self.compile(a:node.left, 1)
  let a:node.right = self.compile(a:node.right, 1)
  if a:node.right.type == s:NODE_IDENTIFIER
    if a:node.right.value =~# '^[gbwtslv]:$'
      call self.error_mes(a:node.right, 'E731', 'using Dictionary as a String', 1)
    endif
  endif
  return a:node

  " @TODO left is a list or a dictionary
"  return {'type' : 'subs', 'l' : left, 'r' : right, 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_dot(node, refchk) " {{{
  let a:node.left = self.compile(a:node.left, 1)
  let a:node.right = self.compile(a:node.right, 0)

  return a:node
"  return {'type' : 'subs', 'l' : left, 'r' : right, 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_number(node) " {{{
  return a:node
"  return { 'type' : 'integer', 'val' : a:node.value, 'node' : a:node}
endfunction " }}}

" map の引数などをどう処理するか?
function s:VimlLint.compile_string(node) " {{{
  return a:node
"  return { 'type' : 'string', 'val' : a:node.value, 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_list(node, refchk) " {{{
  let a:node.value = map(a:node.value, 'self.compile(v:val, 1)')
  return a:node
"  return { 'type' : 'list', 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_dict(node, refchk) " {{{
  " @TODO 文字列のみ
  for i in range(len(a:node.value))
    let v = a:node.value[i]
    let v[0] = self.compile(v[0], 1)
    let v[1] = self.compile(v[1], 1)
  endfor
  return a:node
"  return { 'type' : 'dict', 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_option(node) " {{{
  return a:node
"  return { 'type' : 'option', 'node' : a:node}
endfunction " }}}

function! s:readonly_var(var) " {{{
  if a:var.type == s:NODE_IDENTIFIER
    if a:var.value =~# '^a:.*'
      return 1
    endif

    if a:var.value =~# '^[gbwtsl]:$'
      return 1
    endif
  endif
endfunction " }}}

function! s:reserved_name(name) " {{{
  if a:name == 'a:000' || a:name == 'v:val' || a:name == 's:'
    return 1
  endif
  if a:name =~# '^[gbwtsl]:$'
    return 1
  endif
  if a:name == 'self'
    " @TODO if a function is defined with the "dict" attribute
    return 1
  endif
  if a:name =~# '^a:\d*$'
    return 1
  endif

  return 0
endfunction " }}}

function s:VimlLint.compile_identifier(node, refchk) " {{{
  let name = a:node.value
  if s:reserved_name(name)
  elseif a:refchk
    call s:exists_var(self, self.env, a:node)
"    call self.error_mes(a:node, 'EVLx', 'undefined variable: ' . name, 1)
  endif
  return a:node
"  return {'type' : 'id', 'val' : name, 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_curlyname(node, refchk) " {{{
  for f in a:node.value
    if f.curly
      call self.compile(f.value, 1)
    endif
  endfor

  return a:node
"  return {'type' : 'curly', 'node' : a:node}
endfunction " }}}

function s:VimlLint.compile_env(node, refchk) " {{{
  return a:node
"  return {'type' : 'env', 'node' : a:node}
endfunction " }}}

" register
function s:VimlLint.compile_reg(node) " {{{
  return a:node
"  return {'type' : 'reg', 'val' : a:node.value, 'node' : a:node}
"  echo a:node
"  throw 'NotImplemented: reg'
endfunction " }}}

function s:VimlLint.compile_op1(node, op) " {{{
  let a:node.left = self.compile(a:node.left, 1)

  return a:node
endfunction " }}}

function s:VimlLint.compile_op2(node, op) " {{{

  let a:node.left = self.compile(a:node.left, 1)
  let a:node.right = self.compile(a:node.right, 1)

  return a:node

  " @TODO 比較/演算できる型どうしか.
  " @TODO 演算結果の型を返すようにする
endfunction " }}}

function! s:vimlint_file(filename, param) " {{{
  let vimfile = a:filename
  let p = s:VimLParser.new()
  let c = s:VimlLint.new(a:param)
  try
    if !a:param.quiet
      if has_key(a:param, 'output')
        redraw!
      endif
      echo '.... ' . a:filename . ' start'
    endif

    if has_key(a:param, 'type') && a:param.type == 'string'
        let r = s:StringReader.new(vimfile)
        let c.filename = 'string'
    else
        let r = s:StringReader.new(readfile(vimfile))
        let c.filename = vimfile
    endif
    call c.compile(p.parse(r), 1)

    " global 変数のチェック
    let env = c.env
    for v in keys(env.var)
      if env.var[v].subs == 0
        call c.error_mes(env.var[v].node, 'EVL101', 'undefined variable `' . v . '`', 1)
      endif
    endfor
  catch


    let line = matchstr(v:exception, '.*line \zs\d\+\ze col \d\+$')
    let col  = matchstr(v:exception, '.*line \d\+ col \zs\d\+\ze$')
    let i = 'EVP_0'
    if line == ""
      let msg = substitute(v:throwpoint, '\.\.\zs\d\+', '\=s:numtoname(submatch(0))', 'g') . "\n" . v:exception
    elseif matchstr(v:exception, 'vimlparser: E\d\+:') != ''
      let i = 'EVP_' . matchstr(v:exception, 'vimlparser: \zsE\d\+\ze:')
      let msg = matchstr(v:exception, '.*vimlparser: E\d\+: \zs.*\ze: line \d\+ col \d\+$')
    else
      let msg  = matchstr(v:exception, '.*vimlparser: \zs.*\ze: line \d\+ col \d\+$')

    endif

    call c.error_mes({'pos' : {'lnum' : line, 'col' : col, 'i' : i}}, i, msg, 1)
  finally

    if a:param.outfunc == function('s:output_file')
      if filewritable(c.param.output.filename)
        let lines = extend(readfile(c.param.output.filename), c.error)
      else
        let lines = c.error
      endif
      let lines = extend([a:filename . ' start'], lines)
      call writefile(lines, c.param.output.filename)
    endif

    if !a:param.quiet
      if has_key(c.param, 'output')
        redraw!
      endif
      echo '.... ' . a:filename . ' end'
    endif

    if a:param.outfunc == function('s:output_list')
      return c.error
    else
      return []
    endif
  endtry

endfunction " }}}

function! s:vimlint_dir(dir, param) " {{{
  if a:param.recursive
    let filess = expand(a:dir . "/**/*.vim")
  else
    let filess = expand(a:dir . "/*/*.vim")
  endif
  let ret = []
  for f in split(filess, "\n")
    if filereadable(f)
      let p = s:vimlint_file(f, a:param)
      let ret += p
    endif
  endfor

  return ret
endfunction " }}}

function! vimlint#vimlint(file, ...) " {{{

  " param {{{
  let param = a:0 ? copy(a:1) : {}
  let param = extend(param, s:default_param, 'keep')


  let out_type = "echo"
  if has_key(param, 'output') " {{{
    if type(param.output) == type("")
      let param.output = {'filename' : param.output}
    elseif type(param.output) == type([])
      let out_type = "list"
      unlet param.output
    elseif type(param.output) != type({})
      unlet param.output
    endif

    if has_key(param, 'output')
      let param.output = extend(param.output, s:default_param_output, 'keep')
      if param.output.filename == ''
        unlet param.output
      else
        let out_type = "file"
      endif
    endif
  endif

  if out_type == "file"
    " file
    let param.outfunc = function('s:output_file')
    if !param.output.append
      call writefile([], param.output.filename)
    endif
  elseif out_type == "list"
    let param.outfunc = function('s:output_list')
  else
    " echo
    let param.outfunc = function('s:output_echo')
  endif " }}}
  " }}}

  let files = (type(a:file) == type([])) ? a:file : [a:file]
  let ret = []
  for f in files
    if isdirectory(f)
      let ret += s:vimlint_dir(f, param)
    elseif filereadable(f)
      let ret += s:vimlint_file(f, param)
    else
      echoerr "vimlint: cannot readfile: " . f
    endif
  endfor
  return ret
endfunction " }}}

function! s:numtoname(num) " {{{
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

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0 foldmethod=marker commentstring=\ "\ %s:
