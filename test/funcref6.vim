" @ERR []
function! foo#DictFoldLeft(fn, initial, dict) abort "{{{
  let l:x = a:initial
  for [l:key, l:value] in items(a:dict)
    let l:x = a:fn(l:key, l:value, l:x)
    unlet l:value
  endfor
  return l:x
endfunction "}}}
