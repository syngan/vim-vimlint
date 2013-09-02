###########################
#-*- coding: utf-8 -*-
# :h functions
# の関数リストから辞書を構築する
###########################

# import {{{
import re
# }}}

re1 = re.compile('\).*')
re2 = re.compile('\[.*')
re3 = re.compile('\(.*')
tbl = {}
for line in open('resource/builtin-func', 'r'):
  if line[0] == ' ' or line[0] == '\t':
    continue
  line = line.rstrip('\r\n')
  line = re.sub(re1, ')', line)
  hasdots = (line.count("...") > 0)
  argnum = line.count("{")
  line2 = re.sub(re2, '', line)
  argmin = line2.count("{")
  func = re.sub(re3, '', line2)

  # 例外がいくつかある. bug だと思うが.
  # getreg( [{regname} [, 1]])	String	contents of register
  # mode( [expr])			String	current editing mode
  if func == 'getreg':
    argnum = 2
  if line.count('[expr]') > 0:
    argnum = argnum + 1
  if hasdots:
    argmax = 65535
  else:
    argmax = argnum

  if tbl.has_key(func):
    if tbl[func][0] > argmin:
      tbl[func][0] = argmin
    if tbl[func][1] < argmax:
      tbl[func][1] = argmax
  else:
    tbl[func] = [argmin, argmax]
  # bug: argv, char2nr
  # print "let s:builtin_func.%s = {'min' : %d, 'max': %d}" % (func,argmin, argmax)


for f in sorted(tbl.keys()):
  print "let s:builtin_func.%s = {'min' : %d, 'max': %d}" % (f,tbl[f][0],tbl[f][1])

# vim:set et ts=2 sts=2 sw=2 tw=0 foldmethod=marker:
