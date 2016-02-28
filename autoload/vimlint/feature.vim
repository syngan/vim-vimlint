scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! s:init() abort " {{{
" help の情報は漏れが多くて信用できない
" generated by resource/feature_list.py
  let feature = {
\ 'acl': 1,
\ 'all_builtin_terms': 1,
\ 'amiga': 1,
\ 'arabic': 1,
\ 'arp': 1,
\ 'autocmd': 1,
\ 'balloon_eval': 1,
\ 'balloon_multiline': 1,
\ 'beos': 1,
\ 'browse': 1,
\ 'browsefilter': 1,
\ 'builtin_terms': 1,
\ 'byte_offset': 1,
\ 'channel': 1,
\ 'cindent': 1,
\ 'clientserver': 1,
\ 'clipboard': 1,
\ 'cmdline_compl': 1,
\ 'cmdline_hist': 1,
\ 'cmdline_info': 1,
\ 'comments': 1,
\ 'conceal': 1,
\ 'cryptv': 1,
\ 'cscope': 1,
\ 'cursorbind': 1,
\ 'cursorshape': 1,
\ 'debug': 1,
\ 'dialog_con': 1,
\ 'dialog_gui': 1,
\ 'diff': 1,
\ 'digraphs': 1,
\ 'directx': 1,
\ 'dnd': 1,
\ 'dos16': 1,
\ 'dos32': 1,
\ 'ebcdic': 1,
\ 'emacs_tags': 1,
\ 'eval': 1,
\ 'ex_extra': 1,
\ 'extra_search': 1,
\ 'farsi': 1,
\ 'file_in_path': 1,
\ 'filterpipe': 1,
\ 'find_in_path': 1,
\ 'float': 1,
\ 'fname_case': 1,
\ 'folding': 1,
\ 'footer': 1,
\ 'fork': 1,
\ 'gettext': 1,
\ 'gui': 1,
\ 'gui_athena': 1,
\ 'gui_gnome': 1,
\ 'gui_gtk': 1,
\ 'gui_gtk2': 1,
\ 'gui_gtk3': 1,
\ 'gui_mac': 1,
\ 'gui_motif': 1,
\ 'gui_nextaw': 1,
\ 'gui_photon': 1,
\ 'gui_running': 1,
\ 'gui_win16': 1,
\ 'gui_win32': 1,
\ 'gui_win32s': 1,
\ 'gui_win64': 1,
\ 'hangul_input': 1,
\ 'iconv': 1,
\ 'insert_expand': 1,
\ 'job': 1,
\ 'jumplist': 1,
\ 'keymap': 1,
\ 'langmap': 1,
\ 'libcall': 1,
\ 'linebreak': 1,
\ 'lispindent': 1,
\ 'listcmds': 1,
\ 'localmap': 1,
\ 'lua': 1,
\ 'mac': 1,
\ 'macunix': 1,
\ 'menu': 1,
\ 'mksession': 1,
\ 'modify_fname': 1,
\ 'mouse': 1,
\ 'mouse_dec': 1,
\ 'mouse_gpm': 1,
\ 'mouse_jsbterm': 1,
\ 'mouse_netterm': 1,
\ 'mouse_pterm': 1,
\ 'mouse_sgr': 1,
\ 'mouse_sysmouse': 1,
\ 'mouse_urxvt': 1,
\ 'mouse_xterm': 1,
\ 'mouseshape': 1,
\ 'multi_byte': 1,
\ 'multi_byte_encoding': 1,
\ 'multi_byte_ime': 1,
\ 'multi_lang': 1,
\ 'mzscheme': 1,
\ 'netbeans_enabled': 1,
\ 'netbeans_intg': 1,
\ 'ole': 1,
\ 'os2': 1,
\ 'path_extra': 1,
\ 'perl': 1,
\ 'persistent_undo': 1,
\ 'postscript': 1,
\ 'printer': 1,
\ 'profile': 1,
\ 'python': 1,
\ 'python3': 1,
\ 'qnx': 1,
\ 'quickfix': 1,
\ 'reltime': 1,
\ 'rightleft': 1,
\ 'ruby': 1,
\ 'scrollbind': 1,
\ 'showcmd': 1,
\ 'signs': 1,
\ 'smartindent': 1,
\ 'sniff': 1,
\ 'spell': 1,
\ 'startuptime': 1,
\ 'statusline': 1,
\ 'sun_workshop': 1,
\ 'syntax': 1,
\ 'syntax_items': 1,
\ 'system': 1,
\ 'tag_any_white': 1,
\ 'tag_binary': 1,
\ 'tag_old_static': 1,
\ 'tcl': 1,
\ 'terminfo': 1,
\ 'termresponse': 1,
\ 'textobjects': 1,
\ 'tgetent': 1,
\ 'title': 1,
\ 'toolbar': 1,
\ 'unix': 1,
\ 'unnamedplus': 1,
\ 'user-commands': 1,
\ 'user_commands': 1,
\ 'vertsplit': 1,
\ 'vim_starting': 1,
\ 'viminfo': 1,
\ 'virtualedit': 1,
\ 'visual': 1,
\ 'visualextra': 1,
\ 'vms': 1,
\ 'vreplace': 1,
\ 'wildignore': 1,
\ 'wildmenu': 1,
\ 'win16': 1,
\ 'win32': 1,
\ 'win32unix': 1,
\ 'win64': 1,
\ 'win64unix': 1,
\ 'win95': 1,
\ 'winaltkeys': 1,
\ 'windows': 1,
\ 'writebackup': 1,
\ 'x11': 1,
\ 'xfontset': 1,
\ 'xim': 1,
\ 'xpm': 1,
\ 'xpm_w32': 1,
\ 'xsmp': 1,
\ 'xsmp_interact': 1,
\ 'xterm_clipboard': 1,
\ 'xterm_save': 1,
\} " }}}

  " kaoriya {{{
  let kaoriya = {
        \ 'kaoriya': 1,
        \ 'migemo': 1,
        \ 'guess_encode': 1,
        \ } " }}}

  let dict = feature
  let dict = extend(dict, kaoriya)
  let dict['gui_macvim'] = 1
  let dict['gui_kde'] = 1
  let dict['gui_qt'] = 1
  let dict['nvim'] = 1

  return dict
endfunction " }}}

let s:dict = s:init()

function! vimlint#feature#list() abort " {{{
  return s:dict
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
