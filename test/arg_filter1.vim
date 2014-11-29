" @ERR []
" issue58
call filter(["test", "foo", "bar", "test"], "v:val !=# \"test\"")
call filter(["test", "foo", "bar", "test"], "v:val !=# 'test'")
call filter(["test", "foo", "bar", "test"], 'v:val !=# "test"')
call filter(["test", "foo", "bar", "test"], 'v:val !=# ''test''')
