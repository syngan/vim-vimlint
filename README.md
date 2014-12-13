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

[syntastic.vim](https://github.com/scrooloose/syntastic) which is one of the most popular syntax checking plugin for Vim supports vim-vimlint as a syntax checker of vim script.

Since vim-vimlint is written in vim script, vim-vimlint is very slow.
We recommend you to use vim-vimlint with [vim-watchdogs](https://github.com/osyo-manga/vim-watchdogs) which is an async syntax checking plugin based on [vim-quickrun](https://github.com/thinca/vim-quickrun) and [vimproc](https://github.com/Shougo/vimproc.vim).

# Example

## Pull Requests / Issues

- [Shougo/unite-outline/pull/18](https://github.com/Shougo/unite-outline/pull/18) (`EVL105` use global variables && syntax error)
- [Shougo/unite-outline/pull/14](https://github.com/Shougo/unite-outline/pull/14) (`EVL105` use global variables)
- [vim-jp/vital.vim/issues/95](https://github.com/vim-jp/vital.vim/issues/95) (`EVL101` undefined variable, missing `a:`)
- [thinca/vim-ref/pull/35](https://github.com/thinca/vim-ref/pull/35) (syntax error)
- [Shougo/neobundle.vim/issues/142](https://github.com/Shougo/neobundle.vim/issues/142) (`EVL101` undefined variable)
- [Shougo/vimshell.vim/pull/111](https://github.com/Shougo/vimshell.vim/pull/111)  (`EVL101` undefined variables)
- [vim-jp/vital.vim/commit/d4e9ff0](https://github.com/vim-jp/vital.vim/commit/d4e9ff07b6e37fd96e2d10857bd4fdae522983a0) (`EVL101` undefined variable)
- [scrooloose/syntastic/commit/bf91089](https://github.com/scrooloose/syntastic/commit/f3240e600121f164e276e86fe4e53f8e4ab010f0#diff-bf91089ab4d5be349efb653e97bcaed4)
- [google/vim-maktaba/pull/106](https://github.com/google/vim-maktaba/pull/106) (missing comma)
- [junegunn/vim-easy-align/issues/47](https://github.com/junegunn/vim-easy-align/issues/47) (`E587` :break without :while or :for)
- [mattn/emmet-vim/issues/236](https://github.com/mattn/emmet-vim/issues/236) (`E171` missing `endif`, `EVL108` invalid usage of `substitute()`, `E46` for `a:`)
- [suy/vim-lastnextprevious/issues/1](https://github.com/suy/vim-lastnextprevious/issues/1) (`EVL105` use global variables)
- [gcmt/wildfire.vim/issues/21](https://github.com/gcmt/wildfire.vim/issues/21) (`EVL105` use global variables)
- [gcmt/wildfire.vim/issues/22](https://github.com/gcmt/wildfire.vim/issues/22) (syntax error)
- [ctrlpvim/ctrlp.vim/issues/56](https://github.com/ctrlpvim/ctrlp.vim/issues/56) (missing `endif`)
- [benekastah/neomake/issues/9](https://github.com/benekastah/neomake/issues/9) (`EVL205` missing scriptencoding)
- [davidhalter/jedi-vim/pull/328](https://github.com/davidhalter/jedi-vim/pull/328) (`EVL105` use global variables)
- [davidhalter/jedi-vim/pull/329](https://github.com/davidhalter/jedi-vim/pull/329) (`EVL205` missing scriptencoding)
- [chrisbra/NrrwRgn/issues/32](https://github.com/chrisbra/NrrwRgn/issues/32) (syntax error)
- [tpope/vim-rails/issues/369](https://github.com/tpope/vim-rails/issues/369) (syntax error)
- [Lokaltog/vim-easymotion/issues/201](https://github.com/Lokaltog/vim-easymotion/issues/201) (`EVL101` undefined variable, missing `a:`)
- [junegunn/vim-plug/issues/131](https://github.com/junegunn/vim-plug/issues/131) (missing dot)
- [osyo-manga/vim-anzu/issues/14](https://github.com/osyo-manga/vim-anzu/issues/14) (`EVL106` missing `l:` for a count variable)
- [Shougo/vimshell.vim/issues/177](https://github.com/Shougo/vimshell.vim/issues/177) (`EVL108` invalid format of 1st arg of printf)

# Related Plugin

- [Kuniwak/vint](https://github.com/Kuniwak/vint)
- [ujihisa/vimlint](https://github.com/ujihisa/vimlint)
- [dbakker/vim-lint](https://github.com/dbakker/vim-lint)
- [dahu/VimLint](https://github.com/dahu/VimLint)


# Blog in Japanese

- [vimlint category](http://d.hatena.ne.jp/syngan/searchdiary?word=*[vim-vimlint])
- [vim-vimlint 作った](http://d.hatena.ne.jp/syngan/20131122/1385046290)
- [少しばかり機能追加した](http://d.hatena.ne.jp/syngan/20131130/1385816375)
- [vim-vimlint で Travis-CI 連携](http://d.hatena.ne.jp/syngan/20140321/1395411106)
