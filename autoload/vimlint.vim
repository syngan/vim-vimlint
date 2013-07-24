scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" 最低限やりたいこと {{{
"  - 関数引数を a: 付けずに参照
" - let つけずに変数代入
" - call つけずに関数呼び出し
" - build-in 関数関連

" map 内など文字列で使用した変数のチェックができていない
" @TODO `=` は let 以外で使う場面があるか?
" }}}

call extend(s:, vimlparser#import())

let s:VimlLint = {}

let s:default_param = {
\ 'unused_argument' : 1,
\}

function s:VimlLint.new(param)
  let obj = copy(self)
  let obj.indent = ['']
  let obj.lines = []
  let obj.env = s:env({}, "")
  let obj.param = extend(a:param, s:default_param, 'keep')
  return obj
endfunction

" for debug
function! s:VimlLint.node2str(node) " {{{
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
    return a[a:node.type] . "(" . a:node.type . ")"
endfunction " }}}

function! s:env(outer, funcname)
    let env = {}
    let env.outer = a:outer
    let env.function = a:funcname
    let env.var = {}
    if has_key(a:outer, 'global')
        let env.global = a:outer.global
    else
        let env.global = env
    endif
    return env
endfunction

" 変数参照
" @param var string
" @param node dict: return value of compile
function! s:exists_var(env, node)
    let var = a:node.value
    if var =~# '^[gbwt]:'
        " check できない
        " 型くらいは保存してみる?
        return 1
    elseif var =~# '^[s]:'
        call s:append_var_(a:env.global, var, a:node, 0, -1)
        return 1
    elseif var =~# '^v:'
        " @TODO :help v:
        " @TODO map 内などか?
        return 1
    else
        let env = a:env
        while has_key(env, 'var')
            if has_key(env.var, var)
                call s:append_var_(env, var, a:node, 0, -1)
                return 1
            endif
            let env = env.outer
        endwhile
        return 0
    endif
endfunction

function! s:append_var_(env, var, node, val, cnt)
    if has_key(a:env.var, a:var)
        if a:cnt > 0
            let a:env.var[a:var].subs += 1
        else
            let a:env.var[a:var].ref += 1
        endif
    else
        if a:cnt > 0
            " subs/let
            let a:env.var[a:var] = {'ref' : 0, 'val' : a:val, 'subs' : 1, 'node' : a:node}
        else
            " ref
            let a:env.var[a:var] = {'ref' : 1, 'subs' : 0, 'node' : a:node}
        endif
    endif
endfunction

" 変数代入
" let でいうところの
" left node  = var
" right node = val
" pos = string
function! s:append_var(env, var, val, pos)
    if type(a:var) != type({}) || !has_key(a:var, 'type') || !has_key(a:var, 'node')
        echo "in append_var: invalid input: type=" . type(a:var) . ",pos=" . a:pos
        echo a:var
        throw "stop"
    endif
    if a:var.type == 'id'
        let node = a:var.node
        if a:pos == 'a:'
            " 関数引数
            if a:var.val != '...'
                call s:append_var_(a:env, 'a:' . a:var.val, node, a:val, 1)
            endif
        elseif a:var.val =~# '^[sgbwt]:'
            call s:append_var_(a:env.global, a:var.val, node, a:val, 1)
        else
            call s:append_var_(a:env, a:var.val, node, a:val, 1)
        endif
    elseif a:var.type == 'reg'
        " do nothing
        return
    elseif a:var.type == 'subs'
        " let f.f = xxxx, let f["a"] = xxxx
    elseif a:var.type == 'option'
        " do nothing
    elseif a:var.type == 'curly'
        " ???
    elseif a:var.type == 'env'
        " $xxxx
    else
        call s:VimlLint.error_mes(a:var.node, 'unknown type')
        echo a:var
    endif
endfunction

function! s:delete_var(env, var)
"    unlet a:env.var[a:var]
endfunction

function! s:echonode(node)
    echo "compile. " . s:VimlLint.node2str(a:node) . ", val=" .
    \ (has_key(a:node, "value") ?
    \ (type(a:node.value) ==# type("") ? a:node.value : "@@" . type(a:node.value)) : "%%")
endfunction

function s:VimlLint.compile(node, refchk) " {{{
  if type(a:node) ==# type({}) && has_key(a:node, 'type')
    if a:node.type != 2
"      call s:echonode(a:node)
    endif
  else
"    echo "node=" . type(a:node)
"    echo a:node
  endif
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

function s:VimlLint.compile_body(body, refchk)
  let empty = 1
  for node in a:body
    call self.compile(node, a:refchk)
    if node.type != s:NODE_COMMENT
      let empty = 0
    endif
  endfor
endfunction

function s:VimlLint.compile_toplevel(node, refchk)
  call self.compile_body(a:node.body, a:refchk)
  return self.lines
endfunction

function s:VimlLint.compile_comment(node, refchk)
endfunction

function s:VimlLint.compile_excmd(node, refchk)
" @TODO
" e.g. set cpo&vim
" e.g. a = 3   (let 漏れ)
endfunction

function! s:VimlLint.error_mes(node, mes)
"  echo a:node
  let pos = '[line=' . a:node.pos.lnum . ',col=' . a:node.pos.col . ',i=' . a:node.pos.i . ']: '
  echo pos . a:mes
endfunction

function s:VimlLint.compile_function(node, refchk)
  let left = self.compile(a:node.left, 0) " name of function
  let rlist = map(a:node.rlist, 'self.compile(v:val, 0)')  " list of argument string

  let self.env = s:env(self.env, left)
  for v in rlist
    " E853 if Duplicate argument
    call s:append_var(self.env, v, s:NIL, "a:")
    unlet v
  endfor
  call self.compile_body(a:node.body, 1)

  " 未使用変数は?
  for v in keys(self.env.var)
    if self.env.var[v].ref == 0
      " a: は例外とする, オプションが必要 @TODO
"      echo self.env.var[v]
      if self.param['unused_argument'] || v ==# '^a:'
        call s:VimlLint.error_mes(self.env.var[v].node, 'unused variable `' . v . '`')
      endif
    endif
  endfor

  let self.env = self.env.outer
endfunction

function s:VimlLint.compile_delfunction(node, rechk)
  " @TODO function は定義済か?
endfunction

function s:VimlLint.compile_return(node, refchk)
  if a:node.left is s:NIL
  else
    call self.compile(a:node.left, 1)
  endif
endfunction

function s:VimlLint.compile_excall(node, refchk)
  call self.compile(a:node.left, a:refchk)
endfunction

function s:VimlLint.compile_let(node, rechk)

  if type(a:node.right) != type({})
      echo "compile_let. right is invalid"
      echo a:node
  endif
  let right = self.compile(a:node.right, 1)
  if a:node.left isnot s:NIL
      let left = self.compile(a:node.left, 0)
      call s:append_var(self.env, left, right, "let1")
  else
    let list = map(a:node.list, 'self.compile(v:val, 0)')
    call map(list, 's:append_var(self.env, v:val, right, "letn")')
  endif
endfunction


function s:VimlLint.compile_unlet(node, refchk)
  let list = map(a:node.list, 'self.compile(v:val, 1)')
  for v in list
    " unlet
    call s:delete_var(self.env, v)
  endfor
endfunction

function s:VimlLint.compile_lockvar(node, refchk)
  for var in a:node.list
    if var.type != s:NODE_IDENTIFIER
      call s:VimlLint.error_mes(a:node, 'lockvar: internal variable is required: ' . var)
    endif
    if !s:exists_var(self.env, var)
      call s:VimlLint.error_mes(a:node, 'undefined variable: ' . var)
    endif
  endfor
endfunction

function s:VimlLint.compile_unlockvar(node, refchk)
  for var in a:node.list
    if var.type != s:NODE_IDENTIFIER
      call s:VimlLint.error_mes(a:node, 'lockvar: internal variable is required: ' . var)
    endif
    if !s:exists_var(self.env, var)
      call s:VimlLint.error_mes(a:node, 'undefined variable: ' . var)
    endif
  endfor
endfunction

function s:VimlLint.compile_if(node, refchk)
"  call s:VimlLint.error_mes(a:node, "compile_if")
  call self.compile(a:node.cond, 2)
  call self.compile_body(a:node.body, a:refchk)
  for node in a:node.elseif
    call self.compile(node.cond, 1)
    call self.compile_body(node.body, a:refchk)
  endfor
  if a:node.else isnot s:NIL
    call self.compile_body(a:node.else.body, a:refchk)
  endif
endfunction

function s:VimlLint.compile_while(node, refchk)
  call self.compile(a:node.cond, 1)
  call self.compile_body(a:node.body, a:refchk)
endfunction

function s:VimlLint.compile_for(node, refchk)
  let right = self.compile(a:node.right, 1)

  if a:node.left isnot s:NIL
    let left = self.compile(a:node.left, 0)
    call s:append_var(self.env, left, right, "for")
    " append
"    echo "compile for, left is"
"    echo left
  else
    let list = map(a:node.list, 'self.compile(v:val, 0)')
    call map(list, 's:append_var(self.env, v:val, right, "forn")')
    " append
    if a:node.rest isnot s:NIL
      let rest = self.compile(a:node.rest, a:refchk)
      call add(list, '*' . rest)
    endif
    let left = join(list, ', ')
  endif
  call self.compile_body(a:node.body, 1)
endfunction

function s:VimlLint.compile_continue(node, refchk)
endfunction

function s:VimlLint.compile_break(node, refchk)
endfunction

function s:VimlLint.compile_try(node, refchk)
  call self.compile_body(a:node.body, a:refchk)
  for node in a:node.catch
    if node.pattern isnot s:NIL
      call self.compile_body(node.body, a:refchk)
    else
      call self.compile_body(node.body, a:refchk)
    endif
  endfor
  if a:node.finally isnot s:NIL
    call self.compile_body(a:node.finally.body, a:refchk)
  endif
endfunction

function s:VimlLint.compile_throw(node, refchk)
  call self.compile(a:node.left, 1)
endfunction

function s:VimlLint.compile_echo(node, refchk)
  let list = map(a:node.list, 'self.compile(v:val, 1)')
endfunction

function s:VimlLint.compile_echon(node, refchk)
  let list = map(a:node.list, 'self.compile(v:val, 1)')
endfunction

function s:VimlLint.compile_echohl(node, refchk)
  " @TODO
endfunction

function s:VimlLint.compile_echomsg(node, refchk)
  let list = map(a:node.list, 'self.compile(v:val, 1)')
endfunction

function s:VimlLint.compile_echoerr(node, refchk)
  let list = map(a:node.list, 'self.compile(v:val, 1)')
endfunction

function s:VimlLint.compile_execute(node, refchk)
  let list = map(a:node.list, 'self.compile(v:val, 1)')
endfunction

" expr1: expr2 ? expr1 : expr1
function s:VimlLint.compile_ternary(node, refchk)
  let cond = self.compile(a:node.cond, 1)
  let left = self.compile(a:node.left, 1)
  let right = self.compile(a:node.right, 1)
endfunction

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

function s:VimlLint.compile_call(node, refchk)
  let rlist = map(a:node.rlist, 'self.compile(v:val, 1)')
  let left = self.compile(a:node.left, 0)
  return {'type' : 'call', 'l' : left, 'r' : rlist, 'node' : a:node}
endfunction

function s:VimlLint.compile_slice(node, refchk)
  let r0 = a:node.rlist[0] is s:NIL ? 'nil' : self.compile(a:node.rlist[0], 1)
  let r1 = a:node.rlist[1] is s:NIL ? 'nil' : self.compile(a:node.rlist[1], 1)
  let left = self.compile(a:node.left, 1)
  return {'type' : 'slice', 'l' : left, 'r' : [r0,r1], 'node' : a:node}
endfunction


" 置き換える意味がなさそうな感じになってきた.
function s:VimlLint.compile_subscript(node)
  let left = self.compile(a:node.left, 1)
  let right = self.compile(a:node.right, 0)
  " @TODO left is a list or a dictionary
  return {'type' : 'subs', 'l' : left, 'r' : right, 'node' : a:node}
endfunction

function s:VimlLint.compile_dot(node, refchk)
  let left = self.compile(a:node.left, a:refchk)
  let right = self.compile(a:node.right, 0)
  return {'type' : 'subs', 'l' : left, 'r' : right, 'node' : a:node}
endfunction

function s:VimlLint.compile_number(node)
  return { 'type' : 'integer', 'val' : a:node.value, 'node' : a:node}
endfunction

" map の引数などをどう処理するか?
function s:VimlLint.compile_string(node)
  return { 'type' : 'string', 'val' : a:node.value, 'node' : a:node}
endfunction

function s:VimlLint.compile_list(node, refchk)
  let value = map(a:node.value, 'self.compile(v:val, 1)')
  return { 'type' : 'list', 'node' : a:node}
endfunction

function s:VimlLint.compile_dict(node, refchk)
  " @TODO 文字列のみ
  call map(copy(a:node.value), 'self.compile(v:val[0], 1)')
  call map(a:node.value, 'self.compile(v:val[1], 1)')
  return { 'type' : 'dict', 'node' : a:node}
endfunction

function s:VimlLint.compile_option(node)
  return { 'type' : 'option', 'node' : a:node}
endfunction

function! s:reserved_name(name)
  if a:name == 'a:000' || a:name == 'v:val' || a:name == 's:'
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
endfunction


function s:VimlLint.compile_identifier(node, refchk)
  let name = a:node.value
"echo a:node
  if s:reserved_name(name)
  elseif a:refchk && !s:exists_var(self.env, a:node)
    call s:VimlLint.error_mes(a:node, 'undefined variable: ' . name)
  endif
  return {'type' : 'id', 'val' : name, 'node' : a:node}
endfunction

function s:VimlLint.compile_curlyname(node, refchk)
  echo "culy"
  echo a:node
  return {'type' : 'culy', 'node' : a:node}
endfunction

function s:VimlLint.compile_env(node, refchk)
  return {'type' : 'env', 'node' : a:node}
endfunction

" register
function s:VimlLint.compile_reg(node)
  return {'type' : 'reg', 'val' : a:node.value, 'node' : a:node}
"  echo a:node
"  throw 'NotImplemented: reg'
endfunction

function s:VimlLint.compile_op1(node, op)
  let left = self.compile(a:node.left, 1)
endfunction

function s:VimlLint.compile_op2(node, op)
  let left = self.compile(a:node.left, 1)
  let right = self.compile(a:node.right, 1)
endfunction

function! vimlint#vimlint(filename, param)
  let vimfile = a:filename
  try
    echo '.... ' . a:filename . ' start'
    if has_key(a:param, 'type') && a:param.type == 'string'
        let r = s:StringReader.new(vimfile)
    else
        let r = s:StringReader.new(readfile(vimfile))
    endif
    let p = s:VimLParser.new()
    let c = s:VimlLint.new(a:param)
    call c.compile(p.parse(r), 1)

    " global 変数のチェック
    let env = c.env
    for v in keys(env.var)
      if env.var[v].subs == 0
        call s:VimlLint.error_mes(env.var[v].node, 'undefined variable `' . v . '`')
      endif
    endfor

  catch
    echoerr substitute(v:throwpoint, '\.\.\zs\d\+', '\=s:numtoname(submatch(0))', 'g') . "\n" . v:exception
  finally
    echo '.... ' . a:filename . ' end'
  endtry
endfunction

function! s:numtoname(num)
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
endfunction

"call g:vimlint(g:vimlint_filename)

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0 foldmethod=marker:
