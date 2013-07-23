

* Install
```vim
NeoBundleLazy 'ynkdir/vim-vimlparser', {
	\ 'autoload' : {
	  \ 'functions' : 'vimlparser#import'}}

NeoBundleLazy 'syngan/vim-vimlint', {
	\ 'autoload' : {
	  \ 'functions' : 'vimlint#vimlint'}}
```

* Usage

```vim
call vimlint#vimlint('vim-vimlint/autoload/vimlint.vim', {})
```

