# Install

```vim

NeoBundleLazy 'syngan/vim-vimlint', {
    \ 'depends' : 'ynkdir/vim-vimlparser',
    \ 'autoload' : {
    \ 'functions' : 'vimlint#vimlint'}}
```

# Usage

```vim
call vimlint#vimlint(filename, param)
call vimlint#vimlint('vimlint.vim', {})
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

## undefined variable

```vim
function! neobundle#is_installed(...)
  return type(get(a:000, 0, [])) == type([]) ?
        \ !empty(neobundle#_get_installed_bundles(bundle_names)) :
        \ neobundle#config#is_installed(a:1)
endfunction

```

```vim
[line=202,col=51,i=6693]: undefined variable: bundle_names
```
