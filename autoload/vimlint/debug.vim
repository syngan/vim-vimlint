scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! s:init() " {{{
  let s:node_label = {}
  let s:node_label[1] = 'TOPLEVEL'
  let s:node_label[2] = 'COMMENT'
  let s:node_label[3] = 'EXCMD'
  let s:node_label[4] = 'FUNCTION'
  let s:node_label[5] = 'ENDFUNCTION'
  let s:node_label[6] = 'DELFUNCTION'
  let s:node_label[7] = 'RETURN'
  let s:node_label[8] = 'EXCALL'
  let s:node_label[9] = 'LET'
  let s:node_label[10] = 'UNLET'
  let s:node_label[11] = 'LOCKVAR'
  let s:node_label[12] = 'UNLOCKVAR'
  let s:node_label[13] = 'IF'
  let s:node_label[14] = 'ELSEIF'
  let s:node_label[15] = 'ELSE'
  let s:node_label[16] = 'ENDIF'
  let s:node_label[17] = 'WHILE'
  let s:node_label[18] = 'ENDWHILE'
  let s:node_label[19] = 'FOR'
  let s:node_label[20] = 'ENDFOR'
  let s:node_label[21] = 'CONTINUE'
  let s:node_label[22] = 'BREAK'
  let s:node_label[23] = 'TRY'
  let s:node_label[24] = 'CATCH'
  let s:node_label[25] = 'FINALLY'
  let s:node_label[26] = 'ENDTRY'
  let s:node_label[27] = 'THROW'
  let s:node_label[28] = 'ECHO'
  let s:node_label[29] = 'ECHON'
  let s:node_label[30] = 'ECHOHL'
  let s:node_label[31] = 'ECHOMSG'
  let s:node_label[32] = 'ECHOERR'
  let s:node_label[33] = 'EXECUTE'
  let s:node_label[34] = 'TERNARY'
  let s:node_label[35] = 'OR'
  let s:node_label[36] = 'AND'
  let s:node_label[37] = 'EQUAL'
  let s:node_label[38] = 'EQUALCI'
  let s:node_label[39] = 'EQUALCS'
  let s:node_label[40] = 'NEQUAL'
  let s:node_label[41] = 'NEQUALCI'
  let s:node_label[42] = 'NEQUALCS'
  let s:node_label[43] = 'GREATER'
  let s:node_label[44] = 'GREATERCI'
  let s:node_label[45] = 'GREATERCS'
  let s:node_label[46] = 'GEQUAL'
  let s:node_label[47] = 'GEQUALCI'
  let s:node_label[48] = 'GEQUALCS'
  let s:node_label[49] = 'SMALLER'
  let s:node_label[50] = 'SMALLERCI'
  let s:node_label[51] = 'SMALLERCS'
  let s:node_label[52] = 'SEQUAL'
  let s:node_label[53] = 'SEQUALCI'
  let s:node_label[54] = 'SEQUALCS'
  let s:node_label[55] = 'MATCH'
  let s:node_label[56] = 'MATCHCI'
  let s:node_label[57] = 'MATCHCS'
  let s:node_label[58] = 'NOMATCH'
  let s:node_label[59] = 'NOMATCHCI'
  let s:node_label[60] = 'NOMATCHCS'
  let s:node_label[61] = 'IS'
  let s:node_label[62] = 'ISCI'
  let s:node_label[63] = 'ISCS'
  let s:node_label[64] = 'ISNOT'
  let s:node_label[65] = 'ISNOTCI'
  let s:node_label[66] = 'ISNOTCS'
  let s:node_label[67] = 'ADD'
  let s:node_label[68] = 'SUBTRACT'
  let s:node_label[69] = 'CONCAT'
  let s:node_label[70] = 'MULTIPLY'
  let s:node_label[71] = 'DIVIDE'
  let s:node_label[72] = 'REMAINDER'
  let s:node_label[73] = 'NOT'
  let s:node_label[74] = 'MINUS'
  let s:node_label[75] = 'PLUS'
  let s:node_label[76] = 'SUBSCRIPT'
  let s:node_label[77] = 'SLICE'
  let s:node_label[78] = 'CALL'
  let s:node_label[79] = 'DOT'
  let s:node_label[80] = 'NUMBER'
  let s:node_label[81] = 'STRING'
  let s:node_label[82] = 'LIST'
  let s:node_label[83] = 'DICT'
  let s:node_label[85] = 'OPTION'
  let s:node_label[86] = 'IDENTIFIER'
  let s:node_label[87] = 'CURLYNAME'
  let s:node_label[88] = 'ENV'
  let s:node_label[89] = 'REG'
endfunction " }}}

function! vimlint#debug#node2str(node) " {{{
if type(a:node) == type({}) &&
\  has_key(a:node, 'type') && has_key(s:node_label, a:node.type)
  return s:node_label[a:node.type]
else
  return "unknown"
endif
endfunction " }}}

function! vimlint#debug#echonode(node, refchk) " {{{
  echo "compile. " . s:node2str(a:node) . "(" . a:node.type . "), val=" .
    \ (has_key(a:node, "value") ?
    \ (type(a:node.value) ==# type("") ? a:node.value : "@@" . type(a:node.value)) : "%%") .
    \  ", ref=" . a:refchk
endfunction " }}}

function! vimlint#debug#decho(str) " {{{
  if g:vimlint#debug > 1
    echo a:str
  endif
endfunction " }}}

call s:init()

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
