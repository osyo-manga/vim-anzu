scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! s:pos_less_equal(a, b)
	return a:a[0] == a:b[0] ? a:a[1] <= a:b[1] : a:a[0] <= a:b[0]
endfunction


function! s:get_text_from_region(first, last, ...)
	let wise = get(a:, 1, "v")

	let old_selection = &selection
	let &selection = 'inclusive'

	let register = v:register == "" ? '"' : v:register
	let old_pos = getpos(".")
	let old_reg = getreg(register)
	let old_first = getpos("'[")
	let old_last  = getpos("']")
	try
		call setpos("'[", a:first)
		call setpos("']", a:last)
		execute printf('silent normal! `[%s`]y', wise)
		return getreg(register)
	finally
		call setpos("'[", old_first)
		call setpos("']", old_last)
		call setreg(register, old_reg)
		call setpos(".", old_pos)
		let &selection = old_selection
	endtry
endfunction


function! s:get_text_from_pattern(pattern, ...)
	let wise = get(a:, 1, "v")
	let first = searchpos(a:pattern, "Wncb")
	if first == [0, 0]
		return ""
	endif
	let last = searchpos(a:pattern, "Wnce")
	if last == [0, 0]
		return ""
	endif
	return s:get_text_from_region([0] + first + [0], [0] + last + [0], wise)
endfunction


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


function! s:jump(prefix, key, suffix)
	if !empty(a:prefix) | execute "normal!" a:prefix | endif
	while 1
		if !empty(a:key) | execute "normal!" a:key | endif
		let pattern = '(\d\+/\d\+)'
		let text = s:get_text_from_pattern(pattern)
		if text == "" || text !~ '^' . pattern . '$'
			break
		endif
	endwhile
	if !empty(a:suffix) | execute "normal!" a:suffix | endif
endfunction


function! anzu#mode#start(pattern, key, prefix, suffix, ...)
	if a:pattern == ""
		return
	endif
	let forward_key = get(a:, 1, "n")
	let back_key = get(a:, 2, "N")
	try
		call s:init(a:pattern)
		if a:key != ""
			call s:jump(a:prefix, a:key, a:suffix)
		endif
		call s:hl_cursor("Cursor", getpos(".")[1:])
	catch /^Vim\%((\a\+)\)\=:E/
		call s:finish()
		echohl ErrorMsg | echo matchstr(v:exception, '^Vim(\a\+):\zs.*\ze$') | echohl None
		return
	endtry
	redraw
	let char = s:getchar()
	while char ==# forward_key || char ==# back_key
		if char ==# forward_key
			call s:jump(a:prefix, "n", a:suffix)
		elseif char ==# back_key
			call s:jump(a:prefix, "N", a:suffix)
		else
			call s:jump(a:prefix, char, a:suffix)
		endif
		call s:hl_cursor("Cursor", getpos(".")[1:])
		redraw
		let char = s:getchar()
	endwhile
	let cnt = index(anzu#searchpos(a:pattern, bufnr("%"), 1), getpos(".")[1:2])
	call s:finish()
	if cnt >= 0
		let pos = anzu#getpos(a:pattern, cnt)
		if !empty(pos)
			call cursor(pos[0], pos[1])
		endif
	endif
	call feedkeys(char)
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
		let [first, last] = matchlist(a:range, '\s*\(\d*\)\s*,\s*\(\d*\)\s*')
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


function! s:silent_undo()
	let pos = getpos(".")
	redir => _
	silent undo
	redir END
	call setpos(".", pos)
endfunction


function! s:finish()
	if get(s:, "undo_flag", 0)
		call s:silent_undo()
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


function! anzu#mode#start_from_incsearch_keymapping_expr(forward_key, back_key)
	silent! call anzu#mode#start(@/, "n", "", "", a:forward_key, a:back_key)
	return ""
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
