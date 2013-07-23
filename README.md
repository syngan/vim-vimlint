* Install

```vim

NeoBundleLazy 'syngan/vim-vimlint', {
    \ 'depends' : 'ynkdir/vim-vimlparser',
    \ 'autoload' : {
    \ 'functions' : 'vimlint#vimlint'}}
```

* Usage

```vim
call vimlint#vimlint('vim-vimlint/autoload/vimlint.vim', {})
```

