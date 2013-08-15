" @ERR []
function! s:get_variablelist(dict) "{{{
  let kind_dict = ['0', '""', '()', '[]', '{}', '.']
  return values(map(copy(a:dict), "{
        \ 'word' : 1,
        \ 'kind' : kind_dict[type(v:val)],
        \}"))
endfunction"}}}

