scriptencoding utf-8

" source %
" echo g:vimlint_test("test")

function! s:test(file)
  " @return 

  let has_err = 0
  let err = []
  for line in readfile(a:file)
    if line[0] != '"'
      break
    endif

    if line =~ '" @ERR'
      let err = eval(line[6:])
      if type(err) != type([])
        let err = [err]
      endif
      let has_err  = 1
    endif
  endfor

  if !has_err
    return -1
  endif

  let ret = vimlint#vimlint(a:file, {'output' : [], 'quiet' : 1,})

  if len(ret) != len(err)
    return 0
  endif

  for i in range(len(ret))
    if ret[i][3] != err[i]
      return 0
    endif
  endfor

  return 1

endfunction


function! g:vimlint_test(dir, ...)
  if isdirectory(a:dir)
    let files = expand(a:dir . "/*.vim")
  else
    let files = a:dir
  endif
  let ok = 0
  let ng = 0
  let sk = 0
  let ret = 0
  for f in split(files, '\n')
    let t = s:test(f)
    if t == 0
      echo "invalid: " . f
      let ret = 1
	  let ng += 1
    elseif t < 0
      echo "skip: " . f
	  let sk += 1
	else
	  let ok += 1
    endif
  endfor

  if a:0 == 0
    " echo ( だとハイライトされない
    echo "" . (ok + ng) . " test: ok=" . ok . ", ng=" . ng . ", skip=" . sk
  else
    call writefile(["test=" . (ok+ng), "ok=" . ok, "ng=" . ng, "skip=" . sk], a:1)
  endif
  return ret
endfunction

" vim:set et ts=2 sts=2 sw=2 tw=0 foldmethod=marker commentstring=\ "\ %s:
