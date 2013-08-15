" @ERR []
function! g:hoge()
  let bundles = filter(neobundle#config#get_autoload_bundles(),
        \ "has_key(v:val.autoload, 'filetypes')")
  for filetype in neobundle#util#get_filetypes()
    call neobundle#config#source_bundles(filter(copy(bundles),"
          \ index(neobundle#util#convert2list(
          \     v:val.autoload.filetypes), filetype) >= 0"))
  endfor
endfunction


