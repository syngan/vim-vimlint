###########################
#-*- coding: utf-8 -*-
# eval.c から, feature-list をとってくる.
# help は信用ならない
#
###########################

# import {{{
import re
import sys
# }}}

if len(sys.argv) < 2:
  print 'Usage: feature-list.py evalfunc.c'
  sys.exit(2)

fp = open(sys.argv[1])
for line in fp:
  if re.match('^f_has\(', line):
    break

dict = {}
for line in fp:
  if re.match('^\s*".*",.*', line):
    m = re.search('".*"', line)
    line = line[m.start()+1 : m.end()-1].lower()
    dict[line] = 1
    if re.match('.*win32.*', line):
      win64 = line.replace('win32', 'win64')
      dict[win64] = 1
  elif re.match('^\s*NULL', line):
    break

for line in fp:
  if re.match('\s*else if \(STRICMP\(name, "[0-9a-zA-Z_]+"\) ', line):
    m = re.search('".*"', line)
    line = line[m.start()+1 : m.end()-1].lower()
    dict[line] = 1
  elif re.match('^}', line):
    break

fp.close()

keys = dict.keys()
for k in sorted(keys):
  print "\ '{0}': 1,".format(k)




# vim:set et ts=2 sts=2 sw=2 tw=0 fdm=marker:
