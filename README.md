[![Build Status](https://travis-ci.org/syngan/vim-vimlint.svg?branch=master)](https://travis-ci.org/syngan/vim-vimlint)

# Install

## by Neobundle

```vim

NeoBundle 'syngan/vim-vimlint', {
    \ 'depends' : 'ynkdir/vim-vimlparser'}
```

# Usage

```vim
call vimlint#vimlint(filename [, param])
call vimlint#vimlint('vimlint.vim')
call vimlint#vimlint(directory)
```

- output to the file "hoge"
```vim
call vimlint#vimlint('vimlint.vim', {'output' : 'hoge'})
```

# Travis-CI

Create `.travis.yml` in your plugin's directory.
```
before_script:
    - git clone https://github.com/syngan/vim-vimlint /tmp/vim-vimlint
    - git clone https://github.com/ynkdir/vim-vimlparser /tmp/vim-vimlparser

script:
  - sh /tmp/vim-vimlint/bin/vimlint.sh -l /tmp/vim-vimlint -p /tmp/vim-vimlparser -v autoload
```

- [vim-vimlint で Travis-CI 連携](http://d.hatena.ne.jp/syngan/20140321/1395411106)

# Recommended Plugin

Since vim-vimlint is written in vim script, vim-vimlint is very slow.
We recommend you to use vim-vimlint with [vim-watchdogs](https://github.com/osyo-manga/vim-watchdogs) which is an async syntax check plugin based on [vim-quickrun](https://github.com/thinca/vim-quickrun) and [vimproc](https://github.com/Shougo/vimproc.vim).

# Example

## Pull Requests

- [fixed vimlint error by syngan ? Pull Request #18 ? Shougo/unite-outline](https://github.com/Shougo/unite-outline/pull/18)
- [remove unnecessary global variables by syngan ? Pull Request #14 ? Shougo/unite-outline ? GitHub](https://github.com/Shougo/unite-outline/pull/14)
- [vitalizer s:git_checkout() ? Issue #95 ? vim-jp/vital.vim ? GitHub](https://github.com/vim-jp/vital.vim/issues/95)
- [fix s:validate() by syngan ? Pull Request #35 ? thinca/vim-ref ? GitHub](https://github.com/thinca/vim-ref/pull/35)
- [undefined variable: bundle_names ? Issue #142 ? Shougo/neobundle.vim ? GitHub](https://github.com/Shougo/neobundle.vim/issues/142)
- [fix vimlint error: by syngan ? Pull Request #111 ? Shougo/vimshell.vim ? GitHub](https://github.com/Shougo/vimshell.vim/pull/111)
- https://github.com/vim-jp/vital.vim/commit/d4e9ff07b6e37fd96e2d10857bd4fdae522983a0
- https://github.com/scrooloose/syntastic/commit/f3240e600121f164e276e86fe4e53f8e4ab010f0#diff-bf91089ab4d5be349efb653e97bcaed4

# Blog in Japanese

- [vimlint category](http://d.hatena.ne.jp/syngan/searchdiary?word=*[vim-vimlint])
- [vim-vimlint 作った](http://d.hatena.ne.jp/syngan/20131122/1385046290)
- [少しばかり機能追加した](http://d.hatena.ne.jp/syngan/20131130/1385816375)
- [vim-vimlint で Travis-CI 連携](http://d.hatena.ne.jp/syngan/20140321/1395411106)
