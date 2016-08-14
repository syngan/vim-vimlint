" @ERR []
function Func() " issue 97
  let dic = {}
  let dic.VVV = [1]
  let dic.VVV[:] = [1]
endfunction

