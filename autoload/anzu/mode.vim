scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim



function! s:getchar()
	let char = getchar()
	return type(char) == type(0) ? nr2char(char) : char
endfunction


function! s:hl_cursor(hl, pos)
	if exists("s:hl_cursor_id")
		call matchdelete(s:hl_cursor_id)
	endif
	let s:hl_cursor_id = matchadd(a:hl, printf('\%%%dl\%%%dc', a:pos[0], a:pos[1]))
endfunction


function! anzu#mode#start(pattern, key, prefix, suffix)
	try
		call s:init(a:pattern)
		if !empty(a:prefix) | execute "normal!" a:prefix | endif
		if !empty(a:key)    | execute "normal!" a:key | endif
		if !empty(a:suffix) | execute "normal!" a:suffix | endif
		call s:hl_cursor("Cursor", getpos(".")[1:])
	catch /^Vim\%((\a\+)\)\=:E486/
		call s:finish()
		echom v:throwpoint . " " . v:exception
		echohl ErrorMsg | echo matchstr(v:exception, '^Vim(normal):\zs.*\ze$') | echohl None
		return
	endtry
	redraw
	let char = s:getchar()
	try
		if char == "n"
			call anzu#mode#start(a:pattern, char, a:prefix, a:suffix)
		else
			call s:finish()
			call feedkeys(char, "n")
		endif
	catch /^Vim\%((\a\+)\)\=:E132/
		call s:finish()
		return feedkeys(":call anzu#mode#start(".string(a:pattern).", ".string(char).")\<CR>", "n")
	endtry
endfunction


function! anzu#mode#counter()
	let s:count += 1
	return s:count
endfunction



function! s:substitute(range, pattern, string, flags)
	if a:range ==# "%"
		let first = 1
		let last  = "$"
	elseif a:range =~ '\s*\d+\s*[,;]\s*\d+\s*'
		echo matchlist(a:range, '\s*\(\d+\)\s*,\s*\(\d+\)\s*')
		let [first, last] = matchlist("12123  ,2", '\s*\(\d*\)\s*,\s*\(\d*\)\s*')
	elseif empty(a:range)
		let first = line('.')
		let last  = line('.')
	else
		let first = 1
		let last  = "$"
	endif
	return map(split(substitute(join(getline(first, last), "\n"), a:pattern, a:string, a:flags), "\n", 1), "setline(v:key + first, v:val)")
endfunction


function! s:silent_substitute(range, pattern, string, flags)
	try
		let old_search_pattern = @/
		silent execute printf('%ss/%s/%s/%s', a:range, a:pattern, a:string, a:flags)
		return 1
	catch
		return 0
	finally
		call histdel("search", -1)
		let @/ = old_search_pattern
	endtry
endfunction


let s:anzu_mode = 0

let s:options = {}
function! s:reset_options(option, value)
	let bufnr = bufnr("%")
	let s:options[a:option] = getbufvar(bufnr, a:option)
	call setbufvar(bufnr, a:option, a:value)
endfunction


function! s:matchlines(pattern)
	return map(map(anzu#searchpos(a:pattern), "v:val[0]"), "[v:val, getline(v:val)]")
endfunction


function! s:init(pattern)
	if get(s:, "anzu_mode", 0)
		return
	endif
	let s:undo_flag = 0

	call s:reset_options("&modifiable", 1)
	call s:reset_options("&modified", 0)
	call s:reset_options("&readonly", 0)
	call s:reset_options("&spell", 0)

	let s:buffer_text = s:matchlines(a:pattern)
	let s:undo_file = tempname()
	execute "wundo!" s:undo_file

	let format = "%s(%d\\/%d)"
	let len = len(anzu#searchpos(a:pattern))
	let s:count = 0
	let string = '\=printf("' . format . '", submatch(0), anzu#mode#counter(), ' . len . ')'
	let pos = getpos(".")
	let s:undo_flag = s:silent_substitute('%', '\(' . a:pattern . '\)', string, 'g')
	call setpos(".", pos)

	let &modified = 0

	let @/ = a:pattern
	let s:anzu_mode = 1
	unlet! s:hl_cursor_id

	let s:matchlist = []
	call add(s:matchlist, matchadd("WarningMsg",  (&ignorecase ? '\c' : "") . a:pattern . '\zs(\d\+/\d\+)', 3))
endfunction


function! s:finish()
	if get(s:, "undo_flag", 0)
		call map(s:buffer_text, 'setline(v:val[0], v:val[1])')
		if exists("s:undo_file")
\		&& filereadable(s:undo_file)
			silent execute "rundo" s:undo_file
			call delete(s:undo_file)
		endif
		let &modified = 1
	endif

	for [option, value] in items(s:options)
		call setbufvar(bufnr("%"), option, value)
	endfor
	let s:options = {}

	let s:undo_flag = 0
	let s:anzu_mode = 0
	if exists("s:hl_cursor_id") && s:hl_cursor_id != -1
		call matchdelete(s:hl_cursor_id)
		unlet s:hl_cursor_id
	endif

	for id in s:matchlist
		if id != -1
			call matchdelete(id)
		endif
	endfor
	let s:matchlist = []
endfunction


function! anzu#mode#mapexpr(key, prefix, suffix)
	return ":\<C-u>call anzu#mode#start(@/, " . string(a:key) .", " . string(a:prefix) . ", " . string(a:suffix) . ")\<CR>"
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
