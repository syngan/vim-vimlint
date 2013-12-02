[![Build Status](https://travis-ci.org/syngan/vim-vimlint.png?branch=master)](https://travis-ci.org/syngan/vim-vimlint)

# Install

```vim

NeoBundleLazy 'syngan/vim-vimlint', {
    \ 'depends' : 'ynkdir/vim-vimlparser',
    \ 'autoload' : {
    \ 'functions' : 'vimlint#vimlint'}}
```

# Usage

```vim
call vimlint#vimlint(filename [, param])
call vimlint#vimlint('vimlint.vim')
call vimlint#vimlint(directory)
```

- ignore "unused argument" 
```vim
call vimlint#vimlint('vimlint.vim', {'unused_argument' : 0})
```

- output to the file "hoge"
```vim
call vimlint#vimlint('vimlint.vim', {'output' : 'hoge'})
```

- append to the file "hoge"
```vim
call vimlint#vimlint('vimlint.vim', {'output' : {'filename': 'hoge', 'append': 1}})
```

# Example

## PR

- [remove unnecessary global variables by syngan ? Pull Request #14 ? Shougo/unite-outline ? GitHub](https://github.com/Shougo/unite-outline/pull/14)
- [vitalizer s:git_checkout() ? Issue #95 ? vim-jp/vital.vim ? GitHub](https://github.com/vim-jp/vital.vim/issues/95)
- [fix s:validate() by syngan ? Pull Request #35 ? thinca/vim-ref ? GitHub](https://github.com/thinca/vim-ref/pull/35)
- [undefined variable: bundle_names ? Issue #142 ? Shougo/neobundle.vim ? GitHub](https://github.com/Shougo/neobundle.vim/issues/142)
- [fix vimlint error: by syngan ? Pull Request #111 ? Shougo/vimshell.vim ? GitHub](https://github.com/Shougo/vimshell.vim/pull/111)

## undefined variable

```vim
function! neobundle#is_installed(...)
  return type(get(a:000, 0, [])) == type([]) ?
        \ !empty(neobundle#_get_installed_bundles(bundle_names)) :
        \ neobundle#config#is_installed(a:1)
endfunction

```

```vim
./neobundle.vim/autoload/neobundle.vim:210:51:6882: undefined variable: bundle_names
```

## unused variable

```vim
  " Save options.
  let max_list_save = g:neocomplcache_max_list
  let max_keyword_width_save = g:neocomplcache_max_keyword_width
  let completefunc_save = &l:completefunc
  let manual_start_length = g:neocomplcache_manual_completion_start_length

  try
    .....

    let &l:completefunc = 'neocomplcache#complete#unite_complete'

    ....

  finally
    " Restore options.
    let g:neocomplcache_max_list = max_list_save
    let g:neocomplcache_max_keyword_width = max_keyword_width_save
    let &l:completefunc = 'neocomplcache#complete#auto_complete'
    let g:neocomplcache_manual_completion_start_length = manual_start_length
  endtry

```

```vim
./neocomplcache/autoload/unite/sources/neocomplcache.vim:50:7:2006: unused variable `l:completefunc_save`
```

## E488

```vim

let a = 3
if 0
    if a = 0
		let a = 2
	endif
endif
```
```vim
vimlparser: E488: Trailing characters: =: line 4 col 7
```

## elseif

```vim
        return self._candidates.to_list()
    else
        return []

    elseif self._status ==# g:eskk#dictionary#HR_NO_RESULT
        throw eskk#dictionary#look_up_error(
        \   "Can't look up '"
``` 

```vim
function vimlint#vimlint..VimLParser.parse..VimLParser.parse_one_cmd..VimLParser
.parse_command..VimLParser.parse_cmd_elseif, �� 2^@vimlparser: E582: :elseif wit
hout :if: line 429 col 5
```



